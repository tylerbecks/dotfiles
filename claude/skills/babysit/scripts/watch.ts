#!/usr/bin/env bun

import { mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';

import {
  diffSnapshots,
  hashBody,
  normalizeComment,
  summarizeSnapshot,
  watcherStateVersion,
  type WatchSnapshot,
  type WatchedCheck,
  type WatchedReview,
  type WatchedThread,
} from './watch-state.ts';

type Options = {
  repository: string;
  prNumber: number;
  intervalSeconds: number;
  statePath: string;
  once: boolean;
  maxWaitSeconds: number;
};

type StoredState = {
  version: typeof watcherStateVersion;
  lastSuccessfulPollAt: string;
  snapshot: WatchSnapshot;
  pendingTransition?: TransitionEvent;
};

type TransitionEvent = {
  type: 'TRANSITION';
  observedAt: string;
  changes: ReturnType<typeof diffSnapshots>;
  snapshot: ReturnType<typeof summarizeSnapshot>;
};

type CorePr = {
  number: number;
  url: string;
  state: string;
  isDraft: boolean;
  headRefOid: string;
  baseRefOid: string;
  mergeable: string;
  mergeStateStatus: string;
  reviewDecision: string;
  autoMergeRequest: unknown | null;
  mergedAt: string | null;
  closedAt: string | null;
  statusCheckRollup: Array<Record<string, unknown>> | null;
};

type RestComment = Parameters<typeof normalizeComment>[0];

type RestReview = {
  id: number;
  body: string | null;
  state: string;
  commit_id: string;
  submitted_at: string;
  html_url: string;
  user: { login?: string } | null;
};

type ThreadsResponse = {
  data?: {
    repository?: {
      pullRequest?: {
        reviewThreads: {
          pageInfo: { hasNextPage: boolean; endCursor: string | null };
          nodes: Array<{
            id: string;
            isResolved: boolean;
            isOutdated: boolean;
            path: string;
            line: number | null;
            comments: {
              pageInfo: { hasNextPage: boolean };
              nodes: Array<{
                id: string;
                body: string;
                updatedAt: string;
              }>;
            };
          }>;
        };
      } | null;
    };
  };
  errors?: Array<{ message: string }>;
};

const reviewThreadsQuery = `
query($owner: String!, $repo: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id isResolved isOutdated path line
          comments(first: 100) {
            pageInfo { hasNextPage }
            nodes { id body updatedAt }
          }
        }
      }
    }
  }
}`;

const ghTimeoutMs = parseGhTimeout(process.env.BABYSIT_GH_TIMEOUT_MS);

const options = parseOptions(Bun.argv.slice(2));
const startedAt = Date.now();
let previous: StoredState | undefined;
let stateLoaded = false;
let consecutiveFailures = 0;

while (true) {
  try {
    if (!stateLoaded) {
      try {
        previous = await readStoredState(options.statePath);
      } catch (error) {
        if (!(error instanceof SyntaxError)) throw error;
        await emitWatcherError(error, 1);
      }
      stateLoaded = true;
    }

    if (previous?.pendingTransition !== undefined) {
      await emit(previous.pendingTransition);
      previous = { ...previous, pendingTransition: undefined };
      await writeStoredState(options.statePath, previous);
    }

    const snapshot = await collectSnapshot(options.repository, options.prNumber);
    const changes = diffSnapshots(previous?.snapshot, snapshot);
    const observedAt = new Date().toISOString();
    const transition: TransitionEvent | undefined =
      changes.length === 0
        ? undefined
        : { type: 'TRANSITION', observedAt, changes, snapshot: summarizeSnapshot(snapshot) };
    previous = {
      version: watcherStateVersion,
      lastSuccessfulPollAt: observedAt,
      snapshot,
      ...(transition === undefined ? {} : { pendingTransition: transition }),
    };
    // Persist the outbox before emitting so a crash can replay the transition on restart.
    await writeStoredState(options.statePath, previous);
    consecutiveFailures = 0;

    if (transition !== undefined) {
      await emit(transition);
      previous = { ...previous, pendingTransition: undefined };
      await writeStoredState(options.statePath, previous);
      // Exiting here is the event-delivery contract: "process ended" means
      // "something happened", which every harness can observe. Streaming
      // instead only reaches a caller reading that stream live — a caller that
      // started this detached sees a healthy poll loop and a silent log — so it
      // is not offered. Re-run against the same --state for the next event.
      break;
    }
    if (options.once || snapshot.state === 'MERGED' || snapshot.state === 'CLOSED') break;
  } catch (error) {
    consecutiveFailures += 1;
    // Report the first failure immediately, then every fifth repeat to limit health-event noise.
    if (consecutiveFailures === 1 || consecutiveFailures % 5 === 0) {
      await emitWatcherError(error, consecutiveFailures);
    }
    if (options.once) process.exitCode = 1;
  }

  if (options.once) break;
  // Hand control back on a quiet stretch instead of relying on the caller to
  // wrap this in `timeout`. A caller that forgets goes dark for however long
  // the process happens to live, which is the failure this contract exists to
  // remove; a QUIET wake costs one line and re-arms in the same breath.
  const remainingMs = options.maxWaitSeconds * 1_000 - (Date.now() - startedAt);
  if (remainingMs <= 0) {
    await emit({
      type: 'QUIET',
      observedAt: new Date().toISOString(),
      waitedSeconds: Math.round((Date.now() - startedAt) / 1_000),
      note: 'No transition yet. Re-run the same command to keep waiting.',
    });
    break;
  }
  // Never sleep past the deadline: the wake has to land when the caller was
  // told it would, not a whole poll interval later.
  await Bun.sleep(Math.min(options.intervalSeconds * 1_000, remainingMs));
}

async function collectSnapshot(repository: string, prNumber: number): Promise<WatchSnapshot> {
  const [owner, repo] = splitRepository(repository);
  const core = await runGhJson<CorePr>([
    'pr',
    'view',
    String(prNumber),
    '--repo',
    repository,
    '--json',
    [
      'number',
      'url',
      'state',
      'isDraft',
      'headRefOid',
      'baseRefOid',
      'mergeable',
      'mergeStateStatus',
      'reviewDecision',
      'autoMergeRequest',
      'mergedAt',
      'closedAt',
      'statusCheckRollup',
    ].join(','),
  ]);
  const [comments, reviews, threads] = await Promise.all([
    runGhPaginatedArray<RestComment>(
      `repos/${repository}/issues/${prNumber}/comments?per_page=100`,
    ),
    runGhPaginatedArray<RestReview>(`repos/${repository}/pulls/${prNumber}/reviews?per_page=100`),
    collectReviewThreads(owner, repo, prNumber),
  ]);

  return {
    version: watcherStateVersion,
    repository,
    number: core.number,
    url: core.url,
    state: core.state,
    isDraft: core.isDraft,
    headSha: core.headRefOid,
    baseSha: core.baseRefOid,
    mergeable: core.mergeable,
    mergeStateStatus: core.mergeStateStatus,
    reviewDecision: core.reviewDecision,
    autoMergeEnabled: core.autoMergeRequest !== null,
    mergedAt: core.mergedAt ?? '',
    closedAt: core.closedAt ?? '',
    checks: normalizeChecks(core.statusCheckRollup ?? []),
    comments: comments.map(normalizeComment).sort(compareIds),
    reviews: reviews.map(normalizeReview).sort(compareIds),
    threads: threads.sort(compareIds),
  };
}

async function collectReviewThreads(
  owner: string,
  repo: string,
  prNumber: number,
): Promise<Array<WatchedThread>> {
  const threads: Array<WatchedThread> = [];
  let cursor: string | undefined;

  while (true) {
    const args = [
      'api',
      'graphql',
      '-f',
      `query=${reviewThreadsQuery}`,
      '-F',
      `owner=${owner}`,
      '-F',
      `repo=${repo}`,
      '-F',
      `number=${prNumber}`,
    ];
    if (cursor !== undefined) args.push('-F', `cursor=${cursor}`);
    const response = await runGhJson<ThreadsResponse>(args);
    if (response.errors !== undefined && response.errors.length > 0) {
      throw new Error(response.errors.map((error) => error.message).join('; '));
    }
    const connection = response.data?.repository?.pullRequest?.reviewThreads;
    if (connection === undefined)
      throw new Error(`Could not read review threads for PR #${prNumber}.`);

    for (const thread of connection.nodes) {
      // Nested thread-comment pagination is intentionally unsupported; fail instead of truncating.
      if (thread.comments.pageInfo.hasNextPage) {
        throw new Error(`Review thread ${thread.id} has more than 100 comments.`);
      }
      const commentFingerprint = thread.comments.nodes.map((comment) => ({
        id: comment.id,
        updatedAt: comment.updatedAt,
        bodyHash: hashBody(comment.body),
      }));
      threads.push({
        id: thread.id,
        isResolved: thread.isResolved,
        isOutdated: thread.isOutdated,
        path: thread.path,
        line: thread.line,
        commentsHash: hashBody(JSON.stringify(commentFingerprint)),
        commentCount: commentFingerprint.length,
        lastUpdatedAt: commentFingerprint.at(-1)?.updatedAt ?? '',
      });
    }

    if (!connection.pageInfo.hasNextPage) return threads;
    cursor = connection.pageInfo.endCursor ?? undefined;
    if (cursor === undefined)
      throw new Error('GitHub returned a review-thread page without a cursor.');
  }
}

/** The latest run of each check, not every run GitHub still remembers. */
function normalizeChecks(checks: Array<Record<string, unknown>>): Array<WatchedCheck> {
  const latest = new Map<string, { startedAt: string; check: WatchedCheck }>();
  const normalized = checks.map((check) => {
    const name = stringValue(check.name) || stringValue(check.context);
    const workflowName = stringValue(check.workflowName);
    const detailsUrl = stringValue(check.detailsUrl) || stringValue(check.targetUrl);
    const status = stringValue(check.status) || stringValue(check.state);
    return {
      startedAt: stringValue(check.startedAt),
      check: {
        key: `${stringValue(check.__typename)}\u0000${workflowName}\u0000${name}`,
        name,
        workflowName,
        status,
        conclusion: stringValue(check.conclusion),
        detailsUrl,
      },
    };
  });
  for (const entry of normalized) {
    const seen = latest.get(entry.check.key);
    // Ties and missing timestamps are last-wins, matching the rollup's oldest-first ordering.
    if (seen === undefined || entry.startedAt >= seen.startedAt) latest.set(entry.check.key, entry);
  }
  return [...latest.values()]
    .map((entry) => entry.check)
    .sort((left, right) => left.key.localeCompare(right.key));
}

function normalizeReview(review: RestReview): WatchedReview {
  return {
    id: review.id,
    author: review.user?.login ?? '',
    state: review.state,
    commitSha: review.commit_id,
    submittedAt: review.submitted_at,
    bodyHash: hashBody(review.body),
    url: review.html_url,
  };
}

async function runGhPaginatedArray<T>(endpoint: string): Promise<Array<T>> {
  const pages = await runGhJson<Array<Array<T>>>(['api', '--paginate', '--slurp', endpoint]);
  return pages.flat();
}

async function runGhJson<T>(args: Array<string>): Promise<T> {
  const child = Bun.spawn(['gh', ...args], { stdout: 'pipe', stderr: 'pipe' });
  let timedOut = false;
  const timeout = setTimeout(() => {
    timedOut = true;
    child.kill('SIGKILL');
  }, ghTimeoutMs);
  const [stdout, stderr, exitCode] = await Promise.all([
    new Response(child.stdout).text(),
    new Response(child.stderr).text(),
    child.exited,
  ]);
  clearTimeout(timeout);
  if (timedOut) {
    throw new Error(`gh ${args.slice(0, 2).join(' ')} timed out after ${ghTimeoutMs}ms.`);
  }
  if (exitCode !== 0) {
    throw new Error(`gh ${args.slice(0, 2).join(' ')} failed: ${stderr.trim() || stdout.trim()}`);
  }
  try {
    return JSON.parse(stdout);
  } catch {
    throw new Error(`gh ${args.slice(0, 2).join(' ')} returned invalid JSON.`);
  }
}

async function readStoredState(statePath: string): Promise<StoredState | undefined> {
  try {
    const parsed: StoredState = JSON.parse(await readFile(statePath, 'utf8'));
    // Version bumps intentionally invalidate the old snapshot and establish a fresh baseline.
    if (parsed.version !== watcherStateVersion) return undefined;
    return parsed;
  } catch (error) {
    if (isMissingFileError(error)) return undefined;
    throw error;
  }
}

async function writeStoredState(statePath: string, state: StoredState): Promise<void> {
  await mkdir(dirname(statePath), { recursive: true });
  const temporaryPath = `${statePath}.${process.pid}.tmp`;
  await writeFile(temporaryPath, `${JSON.stringify(state)}\n`, { mode: 0o600 });
  await rename(temporaryPath, statePath);
}

function parseOptions(args: Array<string>): Options {
  let repository = '';
  let prNumber = 0;
  let intervalSeconds = 30;
  let statePath = '';
  let once = false;
  let maxWaitSeconds = 600;

  for (let index = 0; index < args.length; index += 1) {
    const argument = args[index];
    if (argument === '--once') {
      once = true;
      continue;
    }
    const value = args[index + 1];
    if (value === undefined) usage(`Missing value for ${argument}.`);
    if (argument === '--repo') repository = value;
    else if (argument === '--pr') prNumber = Number(value);
    else if (argument === '--interval') intervalSeconds = Number(value);
    else if (argument === '--state') statePath = value;
    else if (argument === '--max-wait') maxWaitSeconds = Number(value);
    else usage(`Unknown argument: ${argument}.`);
    index += 1;
  }

  if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository)) usage('Pass --repo owner/name.');
  if (!Number.isSafeInteger(prNumber) || prNumber <= 0) usage('Pass a positive integer with --pr.');
  if (!Number.isFinite(intervalSeconds) || intervalSeconds < 15) {
    usage('--interval must be at least 15 seconds.');
  }
  // Deliberately allowed below --interval: this bounds total blocking, so a
  // small value means "poll once, then hand control back".
  if (!Number.isFinite(maxWaitSeconds) || maxWaitSeconds <= 0) {
    usage('--max-wait must be a positive number of seconds.');
  }
  if (statePath === '') {
    statePath = join(tmpdir(), 'babysit', `${repository.replace('/', '-')}-${prNumber}.json`);
  }
  return { repository, prNumber, intervalSeconds, statePath, once, maxWaitSeconds };
}

function splitRepository(repository: string): [string, string] {
  const [owner, repo] = repository.split('/');
  if (owner === undefined || repo === undefined)
    throw new Error(`Invalid repository: ${repository}`);
  return [owner, repo];
}

function compareIds(left: { id: number | string }, right: { id: number | string }): number {
  return String(left.id).localeCompare(String(right.id), undefined, { numeric: true });
}

function stringValue(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function parseGhTimeout(value: string | undefined): number {
  if (value === undefined) return 20_000;
  const parsed = Number(value);
  return Number.isSafeInteger(parsed) && parsed > 0 ? parsed : 20_000;
}

function isMissingFileError(error: unknown): boolean {
  return error instanceof Error && 'code' in error && error.code === 'ENOENT';
}

async function emitWatcherError(error: unknown, consecutiveFailures: number): Promise<void> {
  await emit({
    type: 'WATCHER_ERROR',
    observedAt: new Date().toISOString(),
    consecutiveFailures,
    error: error instanceof Error ? error.message : String(error),
  });
}

async function emit(value: unknown): Promise<void> {
  await new Promise<void>((resolve, reject) => {
    process.stdout.write(`${JSON.stringify(value)}\n`, (error) => {
      if (error === null || error === undefined) resolve();
      else reject(error);
    });
  });
}

function usage(message: string): never {
  process.stderr.write(
    `${message}\nUsage: bun watch.ts --repo owner/name --pr NUMBER [--interval SECONDS] [--max-wait SECONDS] [--state PATH] [--once]\n`,
  );
  process.exit(2);
}

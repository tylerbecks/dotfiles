import { afterEach, describe, expect, test } from 'bun:test';
import { chmod, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import {
  diffSnapshots,
  normalizeComment,
  summarizeSnapshot,
  watcherStateVersion,
  type WatchSnapshot,
} from './watch-state.ts';

const temporaryDirectories: Array<string> = [];

afterEach(async () => {
  await Promise.all(
    temporaryDirectories.splice(0).map((directory) => rm(directory, { recursive: true })),
  );
});

describe('comments', () => {
  test('detects a body edit even when updatedAt is unchanged', () => {
    const beforeComment = normalizeComment({ id: 1, body: 'first', updated_at: 'same' });
    const afterComment = normalizeComment({ id: 1, body: 'second', updated_at: 'same' });

    expect(
      diffSnapshots(
        snapshot({ comments: [beforeComment] }),
        snapshot({ comments: [afterComment] }),
      ),
    ).toEqual([expect.objectContaining({ type: 'COMMENT_CHANGED', key: '1' })]);
  });
});

describe('snapshot transitions', () => {
  test('emits a compact baseline for the first observation', () => {
    expect(diffSnapshots(undefined, snapshot())).toEqual([
      expect.objectContaining({ type: 'BASELINE' }),
    ]);
  });

  test('re-baselines a snapshot from an older schema version', () => {
    const oldSnapshot = snapshot();
    Reflect.set(oldSnapshot, 'version', 1);

    expect(diffSnapshots(oldSnapshot, snapshot())).toEqual([
      expect.objectContaining({ type: 'BASELINE' }),
    ]);
  });

  test('emits nothing for an unchanged observation', () => {
    const current = snapshot();
    expect(diffSnapshots(current, structuredClone(current))).toEqual([]);
  });

  test('detects head, auto-merge, check, and thread transitions', () => {
    const before = snapshot({
      checks: [
        {
          key: 'Tests',
          name: 'Tests',
          workflowName: '',
          status: 'IN_PROGRESS',
          conclusion: '',
          detailsUrl: '',
        },
      ],
    });
    const after = snapshot({
      headSha: 'new-head',
      autoMergeEnabled: true,
      checks: [
        {
          key: 'Tests',
          name: 'Tests',
          workflowName: '',
          status: 'COMPLETED',
          conclusion: 'FAILURE',
          detailsUrl: '',
        },
      ],
      threads: [
        {
          id: 'thread-1',
          isResolved: false,
          isOutdated: false,
          path: 'src/a.ts',
          line: 3,
          commentsHash: 'abc',
          commentCount: 1,
          lastUpdatedAt: 'now',
        },
      ],
    });

    expect(diffSnapshots(before, after).map((change) => change.type)).toEqual([
      'HEAD_CHANGED',
      'AUTO_MERGE_CHANGED',
      'CHECK_CHANGED',
      'THREAD_ADDED',
    ]);
  });

  test('detects removed collection entries', () => {
    const before = snapshot({
      comments: [normalizeComment({ id: 1, body: 'removed', updated_at: 'now' })],
    });

    expect(diffSnapshots(before, snapshot())).toEqual([
      expect.objectContaining({ type: 'COMMENT_REMOVED', key: '1' }),
    ]);
  });
});

describe('snapshot summaries', () => {
  test('summarizes auto-merge, checks, and threads', () => {
    const current = snapshot({
      autoMergeEnabled: true,
      checks: [
        {
          key: 'Tests',
          name: 'Tests',
          workflowName: '',
          status: 'COMPLETED',
          conclusion: 'SUCCESS',
          detailsUrl: '',
        },
      ],
      threads: [
        {
          id: 'thread',
          isResolved: false,
          isOutdated: false,
          path: 'src/a.ts',
          line: 1,
          commentsHash: 'hash',
          commentCount: 1,
          lastUpdatedAt: 'now',
        },
      ],
    });

    expect(summarizeSnapshot(current)).toEqual(
      expect.objectContaining({
        autoMergeEnabled: true,
        checks: { SUCCESS: 1 },
        unresolvedThreads: 1,
      }),
    );
  });
});

describe('watcher process', () => {
  test('reports corrupt state and recovers with a fresh baseline', async () => {
    const fixture = await createWatcherFixture();
    await writeFile(fixture.statePath, '{not json');

    const result = await runWatcher(fixture);

    expect(result.exitCode).toBe(0);
    expect(result.stderr).toBe('');
    expect(result.events.map((event) => event.type)).toEqual(['WATCHER_ERROR', 'TRANSITION']);
    expect(result.events[0]?.error).toContain('JSON');
    expect(result.events[1]?.changes).toEqual([expect.objectContaining({ type: 'BASELINE' })]);
  });

  test('does not discard state after a non-parse read failure', async () => {
    const fixture = await createWatcherFixture();
    await mkdir(fixture.statePath);

    const result = await runWatcher(fixture);

    expect(result.exitCode).toBe(1);
    expect(result.events).toEqual([
      expect.objectContaining({ type: 'WATCHER_ERROR', consecutiveFailures: 1 }),
    ]);
  });

  test('replays a persisted transition before polling again', async () => {
    const fixture = await createWatcherFixture();
    const firstRun = await runWatcher(fixture);
    expect(firstRun.exitCode).toBe(0);

    const storedState = JSON.parse(await readFile(fixture.statePath, 'utf8'));
    const pendingTransition = {
      type: 'TRANSITION',
      observedAt: '2026-08-18T00:00:00.000Z',
      changes: [{ type: 'HEAD_CHANGED', before: 'old', after: 'head' }],
      snapshot: { state: 'OPEN', headSha: 'head' },
    };
    storedState.pendingTransition = pendingTransition;
    await writeFile(fixture.statePath, JSON.stringify(storedState));

    const secondRun = await runWatcher(fixture);

    expect(secondRun.exitCode).toBe(0);
    expect(secondRun.events).toEqual([pendingTransition]);
    expect(JSON.parse(await readFile(fixture.statePath, 'utf8')).pendingTransition).toBeUndefined();
  });

  test('kills a timed-out GitHub read and reports watcher health', async () => {
    const fixture = await createWatcherFixture();

    const result = await runWatcher(fixture, {
      FAKE_GH_HANG: '1',
      BABYSIT_GH_TIMEOUT_MS: '25',
    });

    expect(result.exitCode).toBe(1);
    expect(result.events).toEqual([
      expect.objectContaining({
        type: 'WATCHER_ERROR',
        consecutiveFailures: 1,
        error: expect.stringContaining('timed out after 25ms'),
      }),
    ]);
  });

  test('exits once it has emitted a transition, without --once', async () => {
    // The event-delivery contract: a caller learns something happened by the
    // process ending. If this ever goes back to streaming, an agent that starts
    // it detached sees a healthy poll loop and an unread log instead.
    const fixture = await createWatcherFixture();

    const result = await runWatcher(fixture, { FAKE_GH_POPULATED: '1' }, [
      '--repo',
      'octo/repo',
      '--pr',
      '42',
      '--state',
      fixture.statePath,
    ]);

    expect(result.exitCode).toBe(0);
    expect(result.events.map((event) => event.type)).toEqual(['TRANSITION']);
  });

  test('wakes with QUIET when nothing changes before --max-wait', async () => {
    // Control comes back on a quiet stretch too, so a caller cannot go dark
    // waiting on a PR that simply has not moved yet.
    const fixture = await createWatcherFixture();
    const watcherArguments = [
      '--repo',
      'octo/repo',
      '--pr',
      '42',
      '--state',
      fixture.statePath,
      '--max-wait',
      '1',
    ];

    await runWatcher(fixture, { FAKE_GH_POPULATED: '1' }, watcherArguments);
    const second = await runWatcher(fixture, { FAKE_GH_POPULATED: '1' }, watcherArguments);

    expect(second.exitCode).toBe(0);
    expect(second.events.map((event) => event.type)).toEqual(['QUIET']);
  });

  test.each([
    ['invalid repo', ['--repo', 'repo', '--pr', '42']],
    ['invalid PR', ['--repo', 'octo/repo', '--pr', '0']],
    ['short interval', ['--repo', 'octo/repo', '--pr', '42', '--interval', '5']],
    ['non-positive max-wait', ['--repo', 'octo/repo', '--pr', '42', '--max-wait', '0']],
    ['missing value', ['--repo']],
  ])('rejects %s arguments', async (_name, watcherArguments) => {
    const fixture = await createWatcherFixture();

    const result = await runWatcher(fixture, {}, watcherArguments);

    expect(result.exitCode).toBe(2);
    expect(result.stderr).toContain('Usage: bun watch.ts');
    expect(result.events).toEqual([]);
  });

  test('maps populated GitHub responses into persisted state', async () => {
    const fixture = await createWatcherFixture();

    const result = await runWatcher(fixture, { FAKE_GH_POPULATED: '1' });
    const storedState = JSON.parse(await readFile(fixture.statePath, 'utf8'));

    expect(result.exitCode).toBe(0);
    expect(storedState.snapshot).toEqual(
      expect.objectContaining({
        checks: [
          // GitHub retains prior check attempts; only the newest run should survive normalization.
          expect.objectContaining({
            key: 'CheckRun\u0000CI\u0000Tests',
            name: 'Tests',
            conclusion: 'SUCCESS',
          }),
        ],
        comments: [expect.objectContaining({ id: 11, preview: 'hello' })],
        reviews: [expect.objectContaining({ id: 12, commitSha: 'head' })],
        threads: [expect.objectContaining({ id: 'thread-1', commentCount: 1 })],
      }),
    );
  });
});

function snapshot(overrides: Partial<WatchSnapshot> = {}): WatchSnapshot {
  return {
    version: watcherStateVersion,
    repository: 'octo/repo',
    number: 42,
    url: 'https://github.com/octo/repo/pull/42',
    state: 'OPEN',
    isDraft: false,
    headSha: 'head',
    baseSha: 'base',
    mergeable: 'MERGEABLE',
    mergeStateStatus: 'CLEAN',
    reviewDecision: '',
    autoMergeEnabled: false,
    mergedAt: '',
    closedAt: '',
    checks: [],
    comments: [],
    reviews: [],
    threads: [],
    ...overrides,
  };
}

async function createWatcherFixture(): Promise<{
  directory: string;
  statePath: string;
  path: string;
}> {
  const directory = await mkdtemp(join(tmpdir(), 'babysit-test-'));
  temporaryDirectories.push(directory);
  const ghPath = join(directory, 'gh');
  await writeFile(
    ghPath,
    `#!/usr/bin/env bun
if (process.env.FAKE_GH_HANG === '1') await Bun.sleep(60_000);
const args = Bun.argv.slice(2);
if (args[0] === 'pr') {
  console.log(JSON.stringify({
    number: 42,
    url: 'https://github.com/octo/repo/pull/42',
    state: 'OPEN',
    isDraft: false,
    headRefOid: 'head',
    baseRefOid: 'base',
    mergeable: 'MERGEABLE',
    mergeStateStatus: 'CLEAN',
    reviewDecision: '',
    autoMergeRequest: null,
    mergedAt: null,
    closedAt: null,
    statusCheckRollup: process.env.FAKE_GH_POPULATED === '1' ? [{
      __typename: 'CheckRun',
      name: 'Tests',
      workflowName: 'CI',
      status: 'COMPLETED',
      conclusion: 'FAILURE',
      detailsUrl: 'https://example.com/check',
      startedAt: '2026-08-23T10:00:00Z',
    }, {
      __typename: 'CheckRun',
      name: 'Tests',
      workflowName: 'CI',
      status: 'COMPLETED',
      conclusion: 'SUCCESS',
      detailsUrl: 'https://example.com/check',
      startedAt: '2026-08-23T11:00:00Z',
    }] : [],
  }));
} else if (args.includes('graphql')) {
  console.log(JSON.stringify({
    data: {
      repository: {
        pullRequest: {
          reviewThreads: {
            pageInfo: { hasNextPage: false, endCursor: null },
            nodes: process.env.FAKE_GH_POPULATED === '1' ? [{
              id: 'thread-1',
              isResolved: false,
              isOutdated: false,
              path: 'src/a.ts',
              line: 4,
              comments: {
                pageInfo: { hasNextPage: false },
                nodes: [{ id: 'thread-comment', body: 'finding', updatedAt: '2026-01-01' }],
              },
            }] : [],
          },
        },
      },
    },
  }));
} else if (process.env.FAKE_GH_POPULATED !== '1') {
  console.log('[[]]');
} else {
  const endpoint = args.at(-1) ?? '';
  if (endpoint.includes('/issues/42/comments')) {
    console.log(JSON.stringify([[{
      id: 11,
      body: 'hello',
      updated_at: '2026-01-01',
      html_url: 'https://example.com/comment',
      user: { login: 'octocat' },
    }]]));
  } else if (endpoint.includes('/pulls/42/reviews')) {
    console.log(JSON.stringify([[{
      id: 12,
      body: 'review',
      state: 'COMMENTED',
      commit_id: 'head',
      submitted_at: '2026-01-01',
      html_url: 'https://example.com/review',
      user: { login: 'reviewer' },
    }]]));
  } else {
    console.error(\`unexpected endpoint: \${endpoint}\`);
    process.exit(1);
  }
}
`,
  );
  await chmod(ghPath, 0o755);
  return {
    directory,
    statePath: join(directory, 'state.json'),
    path: `${directory}:${process.env.PATH ?? ''}`,
  };
}

async function runWatcher(
  fixture: { statePath: string; path: string },
  environment: Record<string, string> = {},
  watcherArguments: Array<string> = [
    '--repo',
    'octo/repo',
    '--pr',
    '42',
    '--state',
    fixture.statePath,
    '--once',
  ],
): Promise<{
  exitCode: number;
  stderr: string;
  events: Array<Record<string, unknown>>;
}> {
  const watcher = Bun.spawn(
    [process.execPath, join(import.meta.dir, 'watch.ts'), ...watcherArguments],
    {
      env: { ...process.env, ...environment, PATH: fixture.path },
      stdout: 'pipe',
      stderr: 'pipe',
    },
  );
  const [stdout, stderr, exitCode] = await Promise.all([
    new Response(watcher.stdout).text(),
    new Response(watcher.stderr).text(),
    watcher.exited,
  ]);
  return {
    exitCode,
    stderr,
    events: stdout
      .trim()
      .split('\n')
      .filter(Boolean)
      .map((line) => JSON.parse(line)),
  };
}

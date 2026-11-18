import { createHash } from 'node:crypto';

export const watcherStateVersion = 3;

export type WatchedComment = {
  id: number | string;
  author: string;
  updatedAt: string;
  bodyHash: string;
  preview: string;
  url: string;
};

export type WatchedCheck = {
  key: string;
  name: string;
  workflowName: string;
  status: string;
  conclusion: string;
  detailsUrl: string;
};

export type WatchedReview = {
  id: number | string;
  author: string;
  state: string;
  commitSha: string;
  submittedAt: string;
  bodyHash: string;
  url: string;
};

export type WatchedThread = {
  id: string;
  isResolved: boolean;
  isOutdated: boolean;
  path: string;
  line: number | null;
  commentsHash: string;
  commentCount: number;
  lastUpdatedAt: string;
};

export type WatchSnapshot = {
  version: typeof watcherStateVersion;
  repository: string;
  number: number;
  url: string;
  state: string;
  isDraft: boolean;
  headSha: string;
  baseSha: string;
  mergeable: string;
  mergeStateStatus: string;
  reviewDecision: string;
  autoMergeEnabled: boolean;
  mergedAt: string;
  closedAt: string;
  checks: Array<WatchedCheck>;
  comments: Array<WatchedComment>;
  reviews: Array<WatchedReview>;
  threads: Array<WatchedThread>;
};

export type WatchChange = {
  type: string;
  key?: string;
  before?: unknown;
  after?: unknown;
};

export function hashBody(body: string | null | undefined): string {
  return createHash('sha256')
    .update(body ?? '')
    .digest('hex')
    .slice(0, 16);
}

export function normalizeComment(comment: {
  id: number | string;
  body?: string | null;
  updated_at?: string;
  updatedAt?: string;
  html_url?: string;
  url?: string;
  user?: { login?: string } | null;
  author?: { login?: string } | null;
}): WatchedComment {
  const body = comment.body ?? '';
  return {
    id: comment.id,
    author: comment.user?.login ?? comment.author?.login ?? '',
    updatedAt: comment.updated_at ?? comment.updatedAt ?? '',
    bodyHash: hashBody(body),
    preview: previewBody(body),
    url: comment.html_url ?? comment.url ?? '',
  };
}

export function diffSnapshots(
  before: WatchSnapshot | undefined,
  after: WatchSnapshot,
): Array<WatchChange> {
  if (before === undefined || before.version !== watcherStateVersion) {
    // Schema version changes intentionally discard old state and establish a new baseline.
    return [{ type: 'BASELINE', after: summarizeSnapshot(after) }];
  }

  const changes: Array<WatchChange> = [];
  compareScalar(changes, 'PR_STATE_CHANGED', before.state, after.state);
  compareScalar(changes, 'DRAFT_STATE_CHANGED', before.isDraft, after.isDraft);
  compareScalar(changes, 'HEAD_CHANGED', before.headSha, after.headSha);
  compareScalar(changes, 'BASE_CHANGED', before.baseSha, after.baseSha);
  compareScalar(changes, 'MERGEABILITY_CHANGED', before.mergeable, after.mergeable);
  compareScalar(changes, 'MERGE_STATE_CHANGED', before.mergeStateStatus, after.mergeStateStatus);
  compareScalar(changes, 'REVIEW_DECISION_CHANGED', before.reviewDecision, after.reviewDecision);
  compareScalar(changes, 'AUTO_MERGE_CHANGED', before.autoMergeEnabled, after.autoMergeEnabled);

  diffCollection(changes, 'CHECK', before.checks, after.checks, (check) => check.key);
  diffCollection(changes, 'COMMENT', before.comments, after.comments, (comment) =>
    String(comment.id),
  );
  diffCollection(changes, 'REVIEW', before.reviews, after.reviews, (review) => String(review.id));
  diffCollection(changes, 'THREAD', before.threads, after.threads, (thread) => thread.id);

  return changes;
}

export function summarizeSnapshot(snapshot: WatchSnapshot): Record<string, unknown> {
  return {
    repository: snapshot.repository,
    number: snapshot.number,
    url: snapshot.url,
    state: snapshot.state,
    isDraft: snapshot.isDraft,
    headSha: snapshot.headSha,
    baseSha: snapshot.baseSha,
    mergeable: snapshot.mergeable,
    mergeStateStatus: snapshot.mergeStateStatus,
    reviewDecision: snapshot.reviewDecision,
    autoMergeEnabled: snapshot.autoMergeEnabled,
    checks: summarizeStatuses(snapshot.checks, (check) => check.conclusion || check.status),
    unresolvedThreads: snapshot.threads.filter((thread) => !thread.isResolved).length,
  };
}

function previewBody(body: string): string {
  return body
    .replace(/<!--.*?-->/gs, '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 160);
}

function compareScalar(
  changes: Array<WatchChange>,
  type: string,
  before: unknown,
  after: unknown,
): void {
  if (before !== after) changes.push({ type, before, after });
}

function diffCollection<T>(
  changes: Array<WatchChange>,
  prefix: string,
  before: Array<T>,
  after: Array<T>,
  keyFor: (value: T) => string,
): void {
  const beforeByKey = new Map(before.map((value) => [keyFor(value), value]));
  const afterByKey = new Map(after.map((value) => [keyFor(value), value]));

  for (const [key, afterValue] of afterByKey) {
    const beforeValue = beforeByKey.get(key);
    if (beforeValue === undefined) {
      changes.push({ type: `${prefix}_ADDED`, key, after: afterValue });
    } else if (stableJson(beforeValue) !== stableJson(afterValue)) {
      changes.push({ type: `${prefix}_CHANGED`, key, before: beforeValue, after: afterValue });
    }
  }
  for (const [key, beforeValue] of beforeByKey) {
    if (!afterByKey.has(key)) changes.push({ type: `${prefix}_REMOVED`, key, before: beforeValue });
  }
}

function stableJson(value: unknown): string {
  return JSON.stringify(value);
}

function summarizeStatuses<T>(
  values: Array<T>,
  statusFor: (value: T) => string,
): Record<string, number> {
  const counts: Record<string, number> = {};
  for (const value of values) {
    const status = statusFor(value) || 'UNKNOWN';
    counts[status] = (counts[status] ?? 0) + 1;
  }
  return counts;
}

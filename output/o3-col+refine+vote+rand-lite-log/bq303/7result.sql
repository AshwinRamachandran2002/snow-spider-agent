-- all contributions (questions, answers, comments) 
-- made by users 16 712 208 → 18 712 208 between
-- 2019-07-01 and 2019-12-31, returning the user id
-- and the tag string of the related question
WITH limits AS (
  SELECT
    16712208 AS min_user,
    18712208 AS max_user,
    TIMESTAMP('2019-07-01') AS from_ts,
    TIMESTAMP('2019-12-31 23:59:59') AS to_ts
)

SELECT
  user_id,
  tags
FROM (
  ------------------------------------------------------------------
  -- 1. questions authored by the target users
  ------------------------------------------------------------------
  SELECT
    q.owner_user_id      AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  CROSS JOIN limits
  WHERE q.owner_user_id BETWEEN limits.min_user AND limits.max_user
    AND q.creation_date  BETWEEN limits.from_ts AND limits.to_ts

  UNION ALL
  ------------------------------------------------------------------
  -- 2. answers they wrote (tags taken from the parent question)
  ------------------------------------------------------------------
  SELECT
    a.owner_user_id      AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.posts_answers`   AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
       ON q.id = a.parent_id
  CROSS JOIN limits
  WHERE a.owner_user_id BETWEEN limits.min_user AND limits.max_user
    AND a.creation_date  BETWEEN limits.from_ts AND limits.to_ts

  UNION ALL
  ------------------------------------------------------------------
  -- 3. comments placed directly on questions
  ------------------------------------------------------------------
  SELECT
    c.user_id            AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments`        AS c
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
       ON q.id = c.post_id
  CROSS JOIN limits
  WHERE c.user_id        BETWEEN limits.min_user AND limits.max_user
    AND c.creation_date   BETWEEN limits.from_ts AND limits.to_ts

  UNION ALL
  ------------------------------------------------------------------
  -- 4. comments placed on answers (join answer → question for tags)
  ------------------------------------------------------------------
  SELECT
    c.user_id            AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments`        AS c
  JOIN `bigquery-public-data.stackoverflow.posts_answers`   AS a
       ON a.id = c.post_id
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
       ON q.id = a.parent_id
  CROSS JOIN limits
  WHERE c.user_id        BETWEEN limits.min_user AND limits.max_user
    AND c.creation_date   BETWEEN limits.from_ts AND limits.to_ts
);
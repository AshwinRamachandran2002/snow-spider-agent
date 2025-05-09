-- User contributions (comments, answers, questions) and the tags of the
-- question they belong to, for the requested users and time‑frame
WITH
/* 1. Questions the target users asked (the tags are on the same row) */
user_questions AS (
  SELECT
    q.owner_user_id        AS user_id,
    q.tags                 AS tags
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE
        q.owner_user_id BETWEEN 16712208 AND 18712208
    AND q.creation_date >= '2019-07-01' AND q.creation_date < '2020-01-01'
),

/* 2. Answers the target users posted, joined to the parent question to get tags */
user_answers AS (
  SELECT
    a.owner_user_id        AS user_id,
    pq.tags                AS tags
  FROM `bigquery-public-data.stackoverflow.posts_answers`   AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS pq
       ON pq.id = a.parent_id
  WHERE
        a.owner_user_id BETWEEN 16712208 AND 18712208
    AND a.creation_date >= '2019-07-01' AND a.creation_date < '2020-01-01'
),

/* 3. Comments the target users left directly on questions */
user_comments_on_questions AS (
  SELECT
    c.user_id              AS user_id,
    pq.tags                AS tags
  FROM `bigquery-public-data.stackoverflow.comments`        AS c
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS pq
       ON pq.id = c.post_id
  WHERE
        c.user_id BETWEEN 16712208 AND 18712208
    AND c.creation_date >= '2019-07-01' AND c.creation_date < '2020-01-01'
),

/* 4. Comments the target users left on answers (need two hops to reach the question) */
user_comments_on_answers AS (
  SELECT
    c.user_id              AS user_id,
    pq.tags                AS tags
  FROM `bigquery-public-data.stackoverflow.comments`        AS c
  JOIN `bigquery-public-data.stackoverflow.posts_answers`   AS pa
       ON pa.id = c.post_id
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS pq
       ON pq.id = pa.parent_id
  WHERE
        c.user_id BETWEEN 16712208 AND 18712208
    AND c.creation_date >= '2019-07-01' AND c.creation_date < '2020-01-01'
)

-- Bring every contribution together
SELECT user_id, tags FROM user_questions
UNION ALL
SELECT user_id, tags FROM user_answers
UNION ALL
SELECT user_id, tags FROM user_comments_on_questions
UNION ALL
SELECT user_id, tags FROM user_comments_on_answers;
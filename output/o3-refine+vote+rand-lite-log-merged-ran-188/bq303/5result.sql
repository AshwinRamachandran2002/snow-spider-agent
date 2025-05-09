-- Contributions (questions, answers, comments) made between
-- 2019‑07‑01 and 2019‑12‑31 by users whose ids are in
-- [16 712 208 … 18 712 208], together with the tags of the
-- question each contribution relates to.
WITH
-- date limits
limits AS (
  SELECT
    TIMESTAMP('2019-07-01 00:00:00 UTC') AS start_date,
    TIMESTAMP('2020-01-01 00:00:00 UTC') AS end_date
)

-- 1. questions authored by the users
SELECT
  q.owner_user_id            AS user_id,
  q.tags                     AS question_tags
FROM `bigquery-public-data.stackoverflow.posts_questions` q
CROSS JOIN limits l
WHERE q.creation_date >= l.start_date
  AND q.creation_date <  l.end_date
  AND q.owner_user_id BETWEEN 16712208 AND 18712208

UNION ALL

-- 2. answers authored by the users (tags taken from parent question)
SELECT
  a.owner_user_id            AS user_id,
  pq.tags                    AS question_tags
FROM `bigquery-public-data.stackoverflow.posts_answers` a
JOIN `bigquery-public-data.stackoverflow.posts_questions` pq
     ON pq.id = a.parent_id
CROSS JOIN limits l
WHERE a.creation_date >= l.start_date
  AND a.creation_date <  l.end_date
  AND a.owner_user_id BETWEEN 16712208 AND 18712208

UNION ALL

-- 3a. comments made directly on questions
SELECT
  c.user_id                  AS user_id,
  pq.tags                    AS question_tags
FROM `bigquery-public-data.stackoverflow.comments` c
JOIN `bigquery-public-data.stackoverflow.posts_questions` pq
     ON pq.id = c.post_id
CROSS JOIN limits l
WHERE c.creation_date >= l.start_date
  AND c.creation_date <  l.end_date
  AND c.user_id BETWEEN 16712208 AND 18712208

UNION ALL

-- 3b. comments made on answers (need one extra hop to the question)
SELECT
  c.user_id                  AS user_id,
  pq.tags                    AS question_tags
FROM `bigquery-public-data.stackoverflow.comments`        c
JOIN `bigquery-public-data.stackoverflow.posts_answers`   pa
     ON pa.id = c.post_id
JOIN `bigquery-public-data.stackoverflow.posts_questions` pq
     ON pq.id = pa.parent_id
CROSS JOIN limits l
WHERE c.creation_date >= l.start_date
  AND c.creation_date <  l.end_date
  AND c.user_id BETWEEN 16712208 AND 18712208;
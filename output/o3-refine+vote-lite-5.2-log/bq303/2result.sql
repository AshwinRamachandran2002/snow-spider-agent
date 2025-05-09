-- Contributions (questions, answers, comments) made between
-- 2019‑07‑01 and 2019‑12‑31 by users whose ids are in
-- [16 712 208 … 18 712 208].  
-- For every contribution return the contributor’s user_id and
-- the tags of the *question* that the contribution belongs to.
WITH
-- ------------------------------------------------------------------
-- basic reference tables
questions AS (
  SELECT
    id                          AS question_id,
    tags,
    owner_user_id               AS user_id,
    creation_date
  FROM `bigquery-public-data.stackoverflow.posts_questions`
),
answers AS (
  SELECT
    id                          AS answer_id,
    parent_id                   AS question_id,
    owner_user_id               AS user_id,
    creation_date
  FROM `bigquery-public-data.stackoverflow.posts_answers`
),
comments AS (
  SELECT
    id                          AS comment_id,
    post_id,
    user_id,
    creation_date
  FROM `bigquery-public-data.stackoverflow.comments`
),
-- ------------------------------------------------------------------
-- handy constants for the time and user ranges
limits AS (
  SELECT
    TIMESTAMP('2019-07-01') AS start_ts,
    TIMESTAMP('2020-01-01') AS end_ts,
    16712208               AS min_uid,
    18712208               AS max_uid
)
-- ------------------------------------------------------------------
SELECT user_id, tags
FROM (

  -- 1. questions authored
  SELECT q.user_id, q.tags
  FROM questions   q, limits l
  WHERE q.creation_date >= l.start_ts
    AND q.creation_date <  l.end_ts
    AND q.user_id BETWEEN l.min_uid AND l.max_uid
  
  UNION ALL
  
  -- 2. answers authored  → tie back to parent question for tags
  SELECT a.user_id, q.tags
  FROM answers     a
  JOIN questions   q ON q.question_id = a.question_id
  JOIN limits      l ON TRUE
  WHERE a.creation_date >= l.start_ts
    AND a.creation_date <  l.end_ts
    AND a.user_id BETWEEN l.min_uid AND l.max_uid
  
  UNION ALL
  
  -- 3. comments written *on questions*
  SELECT c.user_id, q.tags
  FROM comments    c
  JOIN questions   q ON q.question_id = c.post_id
  JOIN limits      l ON TRUE
  WHERE c.creation_date >= l.start_ts
    AND c.creation_date <  l.end_ts
    AND c.user_id BETWEEN l.min_uid AND l.max_uid
  
  UNION ALL
  
  -- 4. comments written *on answers*  → hop through answer to its question
  SELECT c.user_id, q.tags
  FROM comments    c
  JOIN answers     a ON a.answer_id   = c.post_id
  JOIN questions   q ON q.question_id = a.question_id
  JOIN limits      l ON TRUE
  WHERE c.creation_date >= l.start_ts
    AND c.creation_date <  l.end_ts
    AND c.user_id BETWEEN l.min_uid AND l.max_uid
)
ORDER BY user_id;
-- user‑question‑tag pairs for every contribution made
-- between 2019‑07‑01 and 2019‑12‑31 (inclusive)
-- by users whose ids are in [16 712 208 , 18 712 208]

WITH question_tags AS (
  SELECT
    id   AS question_id,
    tags
  FROM `bigquery-public-data.stackoverflow.posts_questions`
),

-- 1) questions authored in the period
question_contrib AS (
  SELECT
    owner_user_id        AS user_id,
    tags
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE creation_date >= '2019-07-01'
    AND creation_date <  '2020-01-01'
    AND owner_user_id BETWEEN 16712208 AND 18712208
),

-- 2) answers authored in the period (look up parent question for tags)
answer_contrib AS (
  SELECT
    a.owner_user_id      AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
  JOIN question_tags AS q
       ON q.question_id = a.parent_id
  WHERE a.creation_date >= '2019-07-01'
    AND a.creation_date <  '2020-01-01'
    AND a.owner_user_id BETWEEN 16712208 AND 18712208
),

-- 3) comments posted on questions in the period
comment_on_question AS (
  SELECT
    c.user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments` AS c
  JOIN question_tags AS q
       ON q.question_id = c.post_id
  WHERE c.creation_date >= '2019-07-01'
    AND c.creation_date <  '2020-01-01'
    AND c.user_id BETWEEN 16712208 AND 18712208
),

-- 4) comments posted on answers in the period
comment_on_answer AS (
  SELECT
    c.user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments`       AS c
  JOIN `bigquery-public-data.stackoverflow.posts_answers`  AS a
       ON a.id = c.post_id
  JOIN question_tags AS q
       ON q.question_id = a.parent_id
  WHERE c.creation_date >= '2019-07-01'
    AND c.creation_date <  '2020-01-01'
    AND c.user_id BETWEEN 16712208 AND 18712208
)

-- final result: one row per contribution
SELECT user_id, tags
FROM (
  SELECT * FROM question_contrib
  UNION ALL
  SELECT * FROM answer_contrib
  UNION ALL
  SELECT * FROM comment_on_question
  UNION ALL
  SELECT * FROM comment_on_answer
);
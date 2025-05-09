-- Users’ contributions (questions, answers, comments) made between  
-- 2019‑07‑01 00:00:00 UTC and 2019‑12‑31 23:59:59 UTC  
-- by accounts whose ids are in [16 712 208 , 18 712 208].  
-- For every contribution return the contributor’s user‑id and the
-- tag‑string of the question to which that contribution belongs.

WITH

-- 1. questions written by the target users in the period ---------------
questions AS (
SELECT
  q.owner_user_id         AS user_id ,
  q.tags                  AS tags
FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
WHERE q.creation_date BETWEEN TIMESTAMP('2019-07-01') AND TIMESTAMP('2020-01-01')
  AND q.owner_user_id BETWEEN 16712208 AND 18712208
),

-- 2. answers written by the target users in the period -----------------
answers AS (
SELECT
  a.owner_user_id         AS user_id ,
  q.tags                  AS tags
FROM `bigquery-public-data.stackoverflow.posts_answers`     AS a
JOIN `bigquery-public-data.stackoverflow.posts_questions`   AS q
     ON a.parent_id = q.id
WHERE a.creation_date BETWEEN TIMESTAMP('2019-07-01') AND TIMESTAMP('2020-01-01')
  AND a.owner_user_id BETWEEN 16712208 AND 18712208
),

-- 3. comments *directly* on questions ----------------------------------
comments_on_questions AS (
SELECT
  c.user_id               AS user_id ,
  q.tags                  AS tags
FROM `bigquery-public-data.stackoverflow.comments`          AS c
JOIN `bigquery-public-data.stackoverflow.posts_questions`   AS q
     ON c.post_id = q.id
WHERE c.creation_date BETWEEN TIMESTAMP('2019-07-01') AND TIMESTAMP('2020-01-01')
  AND c.user_id BETWEEN 16712208 AND 18712208
),

-- 4. comments on answers (need two hops to get the parent question) ----
comments_on_answers AS (
SELECT
  c.user_id               AS user_id ,
  q.tags                  AS tags
FROM `bigquery-public-data.stackoverflow.comments`          AS c
JOIN `bigquery-public-data.stackoverflow.posts_answers`     AS a
     ON c.post_id = a.id
JOIN `bigquery-public-data.stackoverflow.posts_questions`   AS q
     ON a.parent_id = q.id
WHERE c.creation_date BETWEEN TIMESTAMP('2019-07-01') AND TIMESTAMP('2020-01-01')
  AND c.user_id BETWEEN 16712208 AND 18712208
)

-- ----------------------------------------------------------------------
SELECT user_id , tags
FROM (
      SELECT * FROM questions
      UNION ALL
      SELECT * FROM answers
      UNION ALL
      SELECT * FROM comments_on_questions
      UNION ALL
      SELECT * FROM comments_on_answers
     )
ORDER BY user_id, tags;
/*  User‑contributions (questions, answers, comments) between
    1 Jul 2019 and 31 Dec 2019 made by users whose ids are in the
    range [16 712 208 , 18 712 208].  For every contribution we
    return the contributing user id together with each individual
    tag that belongs to the question the contribution relates to.   */

WITH parameters AS (
  SELECT
    DATE '2019-07-01' AS start_date ,
    DATE '2019-12-31' AS end_date   ,
    16712208          AS min_uid    ,
    18712208          AS max_uid
),

-- Questions written by the target users
q_contrib AS (
  SELECT
    q.owner_user_id          AS user_id ,
    q.id                     AS question_id ,
    q.tags
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  CROSS JOIN parameters p
  WHERE q.owner_user_id BETWEEN p.min_uid AND p.max_uid
    AND DATE(q.creation_date) BETWEEN p.start_date AND p.end_date
),

-- Answers written by the target users (tags come from the parent question)
a_contrib AS (
  SELECT
    a.owner_user_id          AS user_id ,
    q.id                     AS question_id ,
    q.tags
  FROM `bigquery-public-data.stackoverflow.posts_answers`     AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions`   AS q
    ON q.id = a.parent_id
  CROSS JOIN parameters p
  WHERE a.owner_user_id BETWEEN p.min_uid AND p.max_uid
    AND DATE(a.creation_date) BETWEEN p.start_date AND p.end_date
),

-- Comments written by the target users **on questions**
cq_contrib AS (
  SELECT
    c.user_id                AS user_id ,
    q.id                     AS question_id ,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments`          AS c
  JOIN `bigquery-public-data.stackoverflow.posts_questions`   AS q
    ON q.id = c.post_id
  CROSS JOIN parameters p
  WHERE c.user_id BETWEEN p.min_uid AND p.max_uid
    AND DATE(c.creation_date) BETWEEN p.start_date AND p.end_date
),

-- Comments written by the target users **on answers**
ca_contrib AS (
  SELECT
    c.user_id                AS user_id ,
    q.id                     AS question_id ,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments`          AS c
  JOIN `bigquery-public-data.stackoverflow.posts_answers`     AS a
    ON a.id = c.post_id
  JOIN `bigquery-public-data.stackoverflow.posts_questions`   AS q
    ON q.id = a.parent_id
  CROSS JOIN parameters p
  WHERE c.user_id BETWEEN p.min_uid AND p.max_uid
    AND DATE(c.creation_date) BETWEEN p.start_date AND p.end_date
)

-- ------------------------------------------------------------------
-- Final result: one row per contribution × per individual tag
-- ------------------------------------------------------------------
SELECT
  user_id,
  question_id,
  tag
FROM (
  SELECT * FROM q_contrib
  UNION ALL
  SELECT * FROM a_contrib
  UNION ALL
  SELECT * FROM cq_contrib
  UNION ALL
  SELECT * FROM ca_contrib
) AS contributions
CROSS JOIN UNNEST(SPLIT(tags, '|')) AS tag
ORDER BY user_id, question_id, tag;
-- Every contribution (question, answer, comment on question, comment on answer)
-- made in 2019-07-01 – 2019-12-31 by users whose ids are between
-- 16 712 208 and 18 712 208 together with the parent-question’s tag string
WITH
-- ① questions asked by the target users
q AS (
  SELECT
    owner_user_id AS user_id,
    tags
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id BETWEEN 16712208 AND 18712208
    AND creation_date >= '2019-07-01'
    AND creation_date <  '2020-01-01'
),

-- ② answers written by the target users (tags taken from parent question)
a AS (
  SELECT
    a.owner_user_id AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.posts_answers`   AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
        ON a.parent_id = q.id
  WHERE a.owner_user_id BETWEEN 16712208 AND 18712208
    AND a.creation_date >= '2019-07-01'
    AND a.creation_date <  '2020-01-01'
),

-- ③ comments placed directly on questions
cq AS (
  SELECT
    c.user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments`        AS c
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
        ON c.post_id = q.id
  WHERE c.user_id BETWEEN 16712208 AND 18712208
    AND c.creation_date >= '2019-07-01'
    AND c.creation_date <  '2020-01-01'
),

-- ④ comments placed on answers (mapped back to parent question)
ca AS (
  SELECT
    c.user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments`        AS c
  JOIN `bigquery-public-data.stackoverflow.posts_answers`   AS a
        ON c.post_id = a.id
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
        ON a.parent_id = q.id
  WHERE c.user_id BETWEEN 16712208 AND 18712208
    AND c.creation_date >= '2019-07-01'
    AND c.creation_date <  '2020-01-01'
)

SELECT user_id, tags
FROM (
  SELECT * FROM q
  UNION ALL
  SELECT * FROM a
  UNION ALL
  SELECT * FROM cq
  UNION ALL
  SELECT * FROM ca
)
ORDER BY user_id;
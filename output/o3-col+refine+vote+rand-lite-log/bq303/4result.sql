-- User–tag pairs for every contribution (questions, answers, comments)
-- made between 2019-07-01 and 2019-12-31 by users 16 712 208-18 712 208
WITH
-- questions they authored
q AS (
  SELECT
    owner_user_id AS user_id,
    tags
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE creation_date >= '2019-07-01'
    AND creation_date <  '2020-01-01'
    AND owner_user_id BETWEEN 16712208 AND 18712208
),
-- answers they posted (use parent-question tags)
a AS (
  SELECT
    ans.owner_user_id AS user_id,
    que.tags
  FROM `bigquery-public-data.stackoverflow.posts_answers`   AS ans
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS que
    ON que.id = ans.parent_id
  WHERE ans.creation_date >= '2019-07-01'
    AND ans.creation_date <  '2020-01-01'
    AND ans.owner_user_id BETWEEN 16712208 AND 18712208
),
-- comments written directly on questions
cq AS (
  SELECT
    com.user_id,
    que.tags
  FROM `bigquery-public-data.stackoverflow.comments`        AS com
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS que
    ON que.id = com.post_id
  WHERE com.creation_date >= '2019-07-01'
    AND com.creation_date <  '2020-01-01'
    AND com.user_id BETWEEN 16712208 AND 18712208
),
-- comments written on answers (hop through answer to its question)
ca AS (
  SELECT
    com.user_id,
    que.tags
  FROM `bigquery-public-data.stackoverflow.comments`        AS com
  JOIN `bigquery-public-data.stackoverflow.posts_answers`   AS ans
    ON ans.id = com.post_id
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS que
    ON que.id = ans.parent_id
  WHERE com.creation_date >= '2019-07-01'
    AND com.creation_date <  '2020-01-01'
    AND com.user_id BETWEEN 16712208 AND 18712208
)

SELECT DISTINCT user_id, tags
FROM (
  SELECT * FROM q
  UNION ALL
  SELECT * FROM a
  UNION ALL
  SELECT * FROM cq
  UNION ALL
  SELECT * FROM ca
)
ORDER BY user_id, tags;
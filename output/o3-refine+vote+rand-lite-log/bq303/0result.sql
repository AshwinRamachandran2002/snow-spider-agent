WITH question_tags AS (
  SELECT
    id AS question_id,
    tags
  FROM `bigquery-public-data.stackoverflow.posts_questions`
),

-- 1. questions asked by the users
user_questions AS (
  SELECT
    owner_user_id AS user_id,
    tags
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND owner_user_id BETWEEN 16712208 AND 18712208
    AND tags IS NOT NULL
),

-- 2. answers written by the users (join back to the parent question for tags)
user_answers AS (
  SELECT
    a.owner_user_id AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
  JOIN question_tags AS q
    ON q.question_id = a.parent_id
  WHERE a.creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND a.owner_user_id BETWEEN 16712208 AND 18712208
    AND q.tags IS NOT NULL
),

-- 3. comments left by the users on questions
comments_on_questions AS (
  SELECT
    c.user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments` AS c
  JOIN question_tags AS q
    ON q.question_id = c.post_id
  WHERE c.creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND c.user_id BETWEEN 16712208 AND 18712208
    AND q.tags IS NOT NULL
),

-- 4. comments left by the users on answers (need two hops to the question)
comments_on_answers AS (
  SELECT
    c.user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments` AS c
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON a.id = c.post_id
  JOIN question_tags AS q
    ON q.question_id = a.parent_id
  WHERE c.creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND c.user_id BETWEEN 16712208 AND 18712208
    AND q.tags IS NOT NULL
)

-- final result: one row per contribution (deduplicated to user/tag pairs)
SELECT DISTINCT
  user_id,
  tags
FROM (
  SELECT * FROM user_questions
  UNION ALL
  SELECT * FROM user_answers
  UNION ALL
  SELECT * FROM comments_on_questions
  UNION ALL
  SELECT * FROM comments_on_answers
)
ORDER BY
  user_id,
  tags;
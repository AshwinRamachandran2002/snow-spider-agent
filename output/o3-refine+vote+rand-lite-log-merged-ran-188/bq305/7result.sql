-- Top-10 users by the sum of view-counts of questions they are “associated” with
WITH
-- 1.  question owners
owners AS (
  SELECT id AS question_id,
         owner_user_id AS user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id IS NOT NULL
),

-- 2.  authors of accepted answers
accepted AS (
  SELECT q.id AS question_id,
         a.owner_user_id AS user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  JOIN `bigquery-public-data.stackoverflow.posts_answers`     a
        ON q.accepted_answer_id = a.id
  WHERE a.owner_user_id IS NOT NULL
),

-- 3.  answerers whose answer score > 5
high_score AS (
  SELECT parent_id  AS question_id,
         owner_user_id AS user_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE score > 5
    AND owner_user_id IS NOT NULL
),

-- 4.  answerers whose answer contributes > 20 % of the total positive score
relative_score AS (
  WITH totals AS (
    SELECT parent_id,
           SUM(score) AS tot
    FROM `bigquery-public-data.stackoverflow.posts_answers`
    GROUP BY parent_id
  )
  SELECT a.parent_id  AS question_id,
         a.owner_user_id AS user_id
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  JOIN totals t ON t.parent_id = a.parent_id
  WHERE a.owner_user_id IS NOT NULL
    AND a.score > 0
    AND a.score > 0.20 * t.tot
),

-- 5.  answerers whose answers are in the top-3 scores per question
top3 AS (
  SELECT parent_id  AS question_id,
         owner_user_id AS user_id
  FROM (
    SELECT parent_id,
           owner_user_id,
           DENSE_RANK() OVER (PARTITION BY parent_id
                              ORDER BY score DESC) AS rnk
    FROM `bigquery-public-data.stackoverflow.posts_answers`
    WHERE owner_user_id IS NOT NULL
  )
  WHERE rnk <= 3
),

-- 6.  union of all associations (deduplicated)
associations AS (
  SELECT DISTINCT * FROM owners
  UNION DISTINCT SELECT * FROM accepted
  UNION DISTINCT SELECT * FROM high_score
  UNION DISTINCT SELECT * FROM relative_score
  UNION DISTINCT SELECT * FROM top3
)

-- 7.  final aggregation
SELECT
  u.id            AS user_id,
  u.display_name,
  SUM(COALESCE(q.view_count,0)) AS total_views
FROM associations a
JOIN `bigquery-public-data.stackoverflow.posts_questions` q
  ON q.id = a.question_id
JOIN `bigquery-public-data.stackoverflow.users` u
  ON u.id = a.user_id
GROUP BY user_id, display_name
ORDER BY total_views DESC
LIMIT 10;
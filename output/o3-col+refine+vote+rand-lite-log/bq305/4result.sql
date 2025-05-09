-- Top-10 users by combined view-count of questions they are “associated” with
WITH
-- 1.  Owners of the questions
q AS (
  SELECT id AS question_id,
         owner_user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id IS NOT NULL
),

-- 2.  Owners of accepted answers
accepted AS (
  SELECT q.id        AS question_id,
         a.owner_user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  JOIN `bigquery-public-data.stackoverflow.posts_answers`  a
       ON q.accepted_answer_id = a.id
  WHERE a.owner_user_id IS NOT NULL
),

-- 3.  Answers whose score > 5
highscore AS (
  SELECT parent_id        AS question_id,
         owner_user_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE score > 5
    AND owner_user_id IS NOT NULL
),

-- 4.  Answers whose score is positive and > 20 % of the question’s total answer score
pct AS (
  WITH tot AS (
    SELECT parent_id AS question_id,
           SUM(score) AS tot_score
    FROM `bigquery-public-data.stackoverflow.posts_answers`
    GROUP BY parent_id
  )
  SELECT a.parent_id    AS question_id,
         a.owner_user_id
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  JOIN tot t
       ON t.question_id = a.parent_id
  WHERE a.score > 0
    AND a.score > 0.20 * t.tot_score
    AND a.owner_user_id IS NOT NULL
),

-- 5.  Owners of the three highest-scoring answers per question (ties kept)
top3 AS (
  SELECT question_id,
         owner_user_id
  FROM (
    SELECT parent_id            AS question_id,
           owner_user_id,
           RANK() OVER (PARTITION BY parent_id ORDER BY score DESC) AS rnk
    FROM `bigquery-public-data.stackoverflow.posts_answers`
    WHERE owner_user_id IS NOT NULL
  )
  WHERE rnk <= 3
),

-- 6.  Union of all (question,user) associations, deduplicated
assoc AS (
  SELECT * FROM q
  UNION DISTINCT SELECT * FROM accepted
  UNION DISTINCT SELECT * FROM highscore
  UNION DISTINCT SELECT * FROM pct
  UNION DISTINCT SELECT * FROM top3
),

-- 7.  Sum of view-counts per user
user_views AS (
  SELECT
    a.owner_user_id               AS user_id,
    SUM(q.view_count)             AS total_views
  FROM  assoc a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
       ON q.id = a.question_id
  WHERE q.view_count IS NOT NULL
  GROUP BY user_id
)

-- 8.  Top-10 list with display names
SELECT
  u.id            AS user_id,
  u.display_name,
  user_views.total_views
FROM   user_views
JOIN   `bigquery-public-data.stackoverflow.users` u
       ON u.id = user_views.user_id
ORDER BY total_views DESC
LIMIT 10;
-- Top-10 users by the total views of questions they are “associated” with
WITH
/* 1)  Question owners */
question_owner AS (
  SELECT
    id            AS question_id,
    owner_user_id AS user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id IS NOT NULL
),

/* 2)  Owners of accepted answers */
accepted_answer_owner AS (
  SELECT
    q.id          AS question_id,
    a.owner_user_id AS user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON a.id = q.accepted_answer_id
  WHERE a.owner_user_id IS NOT NULL
),

/* 3)  Answers whose score > 5 */
high_score_answers AS (
  SELECT
    parent_id     AS question_id,
    owner_user_id AS user_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE score > 5
    AND owner_user_id IS NOT NULL
),

/* 4)  Answers whose score > 0 and > 20 % of the total answer score for that question */
relatively_high_score AS (
  WITH total_scores AS (
    SELECT parent_id, SUM(score) AS total_score
    FROM `bigquery-public-data.stackoverflow.posts_answers`
    GROUP BY parent_id
  )
  SELECT
    a.parent_id     AS question_id,
    a.owner_user_id AS user_id
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  JOIN total_scores t
        ON t.parent_id = a.parent_id
  WHERE a.score > 0
    AND a.score > 0.20 * t.total_score
    AND a.owner_user_id IS NOT NULL
),

/* 5)  Owners of the three highest-scoring answers per question */
top_three_answers AS (
  SELECT question_id, user_id
  FROM (
    SELECT
      parent_id            AS question_id,
      owner_user_id        AS user_id,
      ROW_NUMBER() OVER (PARTITION BY parent_id
                         ORDER BY score DESC, id) AS rn
    FROM `bigquery-public-data.stackoverflow.posts_answers`
    WHERE owner_user_id IS NOT NULL
  )
  WHERE rn <= 3
),

/* Union all association sources and remove duplicates */
associated AS (
  SELECT DISTINCT * FROM (
    SELECT * FROM question_owner
    UNION ALL SELECT * FROM accepted_answer_owner
    UNION ALL SELECT * FROM high_score_answers
    UNION ALL SELECT * FROM relatively_high_score
    UNION ALL SELECT * FROM top_three_answers
  )
),

/* Sum the view counts of associated questions for each user */
user_views AS (
  SELECT
    a.user_id,
    SUM(COALESCE(q.view_count, 0)) AS total_views
  FROM associated a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
        ON q.id = a.question_id
  GROUP BY a.user_id
)

/* Return the 10 users with the highest combined view counts */
SELECT
  u.id           AS user_id,
  u.display_name,
  uv.total_views
FROM user_views uv
JOIN `bigquery-public-data.stackoverflow.users` u
  ON u.id = uv.user_id
ORDER BY uv.total_views DESC
LIMIT 10;
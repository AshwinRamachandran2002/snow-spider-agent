-- Top-10 users whose associated questions have the largest total view-count
WITH
-- questions with their owners / accepted answer and view count
questions AS (
  SELECT
    id                             AS question_id,
    owner_user_id                  AS owner_id,
    accepted_answer_id,
    COALESCE(view_count,0)         AS view_count
  FROM `bigquery-public-data.stackoverflow.posts_questions`
),

-- every answer (needed for all answer-based rules)
answers AS (
  SELECT
    id                 AS answer_id,
    parent_id          AS question_id,
    owner_user_id      AS answer_owner,
    score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
),

-- total answer score per question (for the “20 % of total” rule)
total_answer_scores AS (
  SELECT
    parent_id          AS question_id,
    SUM(score)         AS total_score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),

-- the three highest-scoring answers for each question
top3_answers AS (
  SELECT
    answer_owner AS user_id,
    question_id
  FROM (
    SELECT
      answer_owner,
      question_id,
      ROW_NUMBER() OVER (PARTITION BY question_id ORDER BY score DESC) AS rn
    FROM answers)
  WHERE rn <= 3
),

/* ------------------------------------------------------------------ */
/*  build the complete question ⇢ user association list (five rules)  */
/* ------------------------------------------------------------------ */
associations AS (

  /* 1) question owner */
  SELECT owner_id               AS user_id, question_id
  FROM questions
  WHERE owner_id IS NOT NULL

  UNION DISTINCT

  /* 2) owner of the accepted answer */
  SELECT a.answer_owner         AS user_id, q.question_id
  FROM questions      AS q
  JOIN answers        AS a ON q.accepted_answer_id = a.answer_id
  WHERE a.answer_owner IS NOT NULL

  UNION DISTINCT

  /* 3) answers with score > 5 */
  SELECT answer_owner           AS user_id, question_id
  FROM answers
  WHERE score > 5
    AND answer_owner IS NOT NULL

  UNION DISTINCT

  /* 4) answers whose score > 0 and > 20 % of the total score */
  SELECT a.answer_owner         AS user_id, a.question_id
  FROM answers              AS a
  JOIN total_answer_scores  AS t USING (question_id)
  WHERE a.score > 0
    AND a.score > 0.2 * t.total_score
    AND a.answer_owner IS NOT NULL

  UNION DISTINCT

  /* 5) owners of the three highest-scoring answers */
  SELECT * FROM top3_answers
),

/* --------------------------------------------------------------- */
/*  sum view counts of all questions associated with each user     */
/* --------------------------------------------------------------- */
user_views AS (
  SELECT
    user_id,
    SUM(q.view_count) AS total_views
  FROM associations
  JOIN questions q USING (question_id)
  GROUP BY user_id
)

/* ------------------------------- */
/*  final top-10 users by views    */
/* ------------------------------- */
SELECT
  u.display_name,
  uv.user_id,
  uv.total_views
FROM user_views AS uv
LEFT JOIN `bigquery-public-data.stackoverflow.users` AS u
       ON uv.user_id = u.id
ORDER BY uv.total_views DESC
LIMIT 10;
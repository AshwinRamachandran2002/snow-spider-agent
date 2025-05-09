WITH
/* ---------- questions with view counts ---------- */
questions AS (
  SELECT
    id AS question_id,
    owner_user_id AS question_owner,
    accepted_answer_id,
    view_count
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE view_count IS NOT NULL
),
/* ---------- all answers ---------- */
answers AS (
  SELECT
    id AS answer_id,
    parent_id AS question_id,
    owner_user_id AS answer_owner,
    score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
),
/* ---------- total answer score per question (for 20 % rule) ---------- */
total_scores AS (
  SELECT
    question_id,
    SUM(score) AS total_score
  FROM answers
  GROUP BY question_id
),
/* ---------- rule 1 : question authors ---------- */
assoc_question_owner AS (
  SELECT
    question_id,
    question_owner AS user_id
  FROM questions
  WHERE question_owner IS NOT NULL
),
/* ---------- rule 2 : accepted‑answer authors ---------- */
assoc_accepted_answerer AS (
  SELECT
    q.question_id,
    a.answer_owner AS user_id
  FROM questions q
  JOIN answers a
    ON q.accepted_answer_id = a.answer_id
  WHERE a.answer_owner IS NOT NULL
),
/* ---------- rule 3 : answers with score > 5 ---------- */
assoc_score_gt5 AS (
  SELECT
    question_id,
    answer_owner AS user_id
  FROM answers
  WHERE score > 5
    AND answer_owner IS NOT NULL
),
/* ---------- rule 4 : answers ≥ 20 % of total score and > 0 ---------- */
assoc_pct20 AS (
  SELECT
    a.question_id,
    a.answer_owner AS user_id
  FROM answers a
  JOIN total_scores t
    ON a.question_id = t.question_id
  WHERE a.score > 0
    AND a.score >= 0.20 * t.total_score
    AND a.answer_owner IS NOT NULL
),
/* ---------- rule 5 : top‑3 highest‑scoring answers per question ---------- */
assoc_top3 AS (
  SELECT
    question_id,
    answer_owner AS user_id
  FROM (
    SELECT
      question_id,
      answer_owner,
      DENSE_RANK() OVER (PARTITION BY question_id ORDER BY score DESC) AS rnk
    FROM answers
    WHERE answer_owner IS NOT NULL
  )
  WHERE rnk <= 3
),
/* ---------- union of all association rules ---------- */
all_associations AS (
  SELECT DISTINCT question_id, user_id FROM (
    SELECT * FROM assoc_question_owner
    UNION ALL
    SELECT * FROM assoc_accepted_answerer
    UNION ALL
    SELECT * FROM assoc_score_gt5
    UNION ALL
    SELECT * FROM assoc_pct20
    UNION ALL
    SELECT * FROM assoc_top3
  )
),
/* ---------- aggregate question views per user ---------- */
user_view_totals AS (
  SELECT
    a.user_id,
    SUM(q.view_count) AS combined_view_count
  FROM all_associations a
  JOIN questions q
    ON a.question_id = q.question_id
  GROUP BY a.user_id
)
/* ---------- final top‑10 users ---------- */
SELECT
  u.user_id,
  COALESCE(us.display_name, '') AS user_display_name,
  u.combined_view_count
FROM user_view_totals u
LEFT JOIN `bigquery-public-data.stackoverflow.users` us
  ON u.user_id = us.id
ORDER BY
  combined_view_count DESC,
  user_id
LIMIT 10;
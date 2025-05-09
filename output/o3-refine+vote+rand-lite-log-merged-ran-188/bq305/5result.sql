WITH questions AS (
  SELECT
    id                       AS qid,
    owner_user_id            AS q_owner,
    accepted_answer_id,
    COALESCE(view_count,0)   AS views
  FROM `bigquery-public-data.stackoverflow.posts_questions`
),

answers AS (
  SELECT
    id,
    parent_id                AS qid,
    owner_user_id            AS a_owner,
    score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
),

/* ---------- associations per rule A–E ---------- */
-- A. owners of the question itself
assoc_q_owner AS (
  SELECT qid, q_owner AS user_id
  FROM questions
  WHERE q_owner IS NOT NULL
),

-- B. owners of the accepted answer
assoc_accepted AS (
  SELECT q.qid, a.a_owner AS user_id
  FROM questions q
  JOIN answers  a ON a.id = q.accepted_answer_id
),

-- C. answers with score > 5
assoc_high_score AS (
  SELECT qid, a_owner AS user_id
  FROM answers
  WHERE score > 5
),

-- D. answers with score > 0 AND > 20 % of total score for that question
totals AS (
  SELECT qid, SUM(score) AS total_score
  FROM answers
  GROUP BY qid
),
assoc_pct AS (
  SELECT a.qid, a.a_owner AS user_id
  FROM answers a
  JOIN totals  t USING (qid)
  WHERE a.score > 0
    AND a.score > 0.2 * t.total_score
),

-- E. owners of the top-3 highest–scoring answers per question
ranked AS (
  SELECT
    qid,
    a_owner,
    ROW_NUMBER() OVER (PARTITION BY qid
                       ORDER BY score DESC, id) AS rn
  FROM answers
),
assoc_top3 AS (
  SELECT qid, a_owner AS user_id
  FROM ranked
  WHERE rn <= 3
),

/* ---------- combine and de-duplicate ---------- */
all_assoc AS (
  SELECT * FROM assoc_q_owner
  UNION ALL SELECT * FROM assoc_accepted
  UNION ALL SELECT * FROM assoc_high_score
  UNION ALL SELECT * FROM assoc_pct
  UNION ALL SELECT * FROM assoc_top3
),
distinct_assoc AS (
  SELECT DISTINCT qid, user_id
  FROM all_assoc
),

/* ---------- sum view-counts per user ---------- */
user_view_totals AS (
  SELECT
    user_id,
    SUM(q.views) AS total_views
  FROM distinct_assoc da
  JOIN questions q ON q.qid = da.qid
  GROUP BY user_id
)

/* ---------- top 10 users by combined views ---------- */
SELECT
  u.id            AS user_id,
  u.display_name,
  uv.total_views
FROM user_view_totals uv
JOIN `bigquery-public-data.stackoverflow.users` u
  ON u.id = uv.user_id
ORDER BY uv.total_views DESC
LIMIT 10;
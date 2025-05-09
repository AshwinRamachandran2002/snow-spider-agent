WITH
-- keep only needed columns from questions, make sure view_count is numeric
questions AS (
  SELECT
    id                              AS question_id,
    IFNULL(CAST(view_count AS INT64),0) AS view_count,
    owner_user_id,
    accepted_answer_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE view_count IS NOT NULL AND view_count > 0
),

-- answers with the columns we need
answers AS (
  SELECT
    id,
    parent_id           AS question_id,
    owner_user_id,
    IFNULL(score,0)     AS score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL            -- ignore anonymous / deleted users
),

-- total answer score per question
total_answer_scores AS (
  SELECT
    question_id,
    SUM(score) AS total_score
  FROM answers
  GROUP BY question_id
),

-- rank answers per question to get the top‑3 later
ranked_answers AS (
  SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY question_id ORDER BY score DESC, id) AS rn
  FROM answers a
),

/*  ----- associations for each rule ------------------------------------- */
assoc_question_owner AS (
  SELECT
    q.question_id,
    q.view_count,
    q.owner_user_id AS user_id
  FROM questions q
  WHERE q.owner_user_id IS NOT NULL
),

assoc_accepted_answer AS (
  SELECT
    q.question_id,
    q.view_count,
    a.owner_user_id AS user_id
  FROM questions q
  JOIN answers a
    ON a.id = q.accepted_answer_id
),

assoc_score_gt5 AS (
  SELECT
    q.question_id,
    q.view_count,
    r.owner_user_id AS user_id
  FROM questions q
  JOIN ranked_answers r
    ON r.question_id = q.question_id
  WHERE r.score > 5
),

assoc_score_pct AS (
  SELECT
    q.question_id,
    q.view_count,
    r.owner_user_id AS user_id
  FROM questions q
  JOIN ranked_answers r
    ON r.question_id = q.question_id
  JOIN total_answer_scores t
    ON t.question_id = q.question_id
  WHERE r.score > 0
    AND r.score > 0.20 * t.total_score          -- > 20 % of total answer scores
),

assoc_top3 AS (
  SELECT
    q.question_id,
    q.view_count,
    r.owner_user_id AS user_id
  FROM questions q
  JOIN ranked_answers r
    ON r.question_id = q.question_id
  WHERE r.rn <= 3                               -- within three highest scores
),

/*  ---------------------------------------------------------------------- */
all_associations AS (
  SELECT * FROM assoc_question_owner
  UNION ALL
  SELECT * FROM assoc_accepted_answer
  UNION ALL
  SELECT * FROM assoc_score_gt5
  UNION ALL
  SELECT * FROM assoc_score_pct
  UNION ALL
  SELECT * FROM assoc_top3
),

-- make sure one (question,user) pair is counted only once
dedup AS (
  SELECT DISTINCT
    question_id,
    user_id,
    view_count
  FROM all_associations
)

/*  final aggregation ----------------------------------------------------- */
SELECT
  u.display_name,
  d.user_id,
  SUM(d.view_count) AS total_question_views
FROM dedup d
LEFT JOIN `bigquery-public-data.stackoverflow.users` u
       ON u.id = d.user_id
GROUP BY
  user_id, display_name
ORDER BY
  total_question_views DESC,
  user_id
LIMIT 10;
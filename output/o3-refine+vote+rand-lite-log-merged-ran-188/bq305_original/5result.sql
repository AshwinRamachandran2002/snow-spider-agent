WITH questions AS (
  SELECT
    id                              AS question_id,
    COALESCE(view_count,0)          AS view_count,
    owner_user_id,
    accepted_answer_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
),

-- 1.  Owner of the question
question_owner AS (
  SELECT
    question_id,
    owner_user_id AS user_id
  FROM questions
  WHERE owner_user_id IS NOT NULL
),

-- 2.  Accepted‑answer owner
accepted AS (
  SELECT
    q.question_id,
    a.owner_user_id AS user_id
  FROM questions q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` a
        ON a.id = q.accepted_answer_id
  WHERE a.owner_user_id IS NOT NULL
),

-- Prepare total answer score per question
answer_totals AS (
  SELECT
    parent_id AS question_id,
    SUM(COALESCE(score,0)) AS total_answer_score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),

-- Rank answers inside each question by score
answers_ranked AS (
  SELECT
    a.parent_id          AS question_id,
    a.owner_user_id      AS user_id,
    a.score,
    RANK() OVER (PARTITION BY a.parent_id ORDER BY a.score DESC, a.id) AS score_rank
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  WHERE a.owner_user_id IS NOT NULL
),

-- 3/4/5. Answers that meet any “significant” criterion
significant_answers AS (
  SELECT
    ar.question_id,
    ar.user_id
  FROM answers_ranked ar
  LEFT JOIN answer_totals t
         ON t.question_id = ar.question_id
  WHERE
        ar.score > 5
     OR (ar.score > 0 AND ar.score > 0.20 * t.total_answer_score)
     OR (ar.score_rank <= 3)
),

-- Union all association sources, removing duplicates
all_associations AS (
  SELECT DISTINCT * FROM question_owner
  UNION DISTINCT
  SELECT DISTINCT * FROM accepted
  UNION DISTINCT
  SELECT DISTINCT * FROM significant_answers
),

-- Sum question view counts per associated user
user_views AS (
  SELECT
    a.user_id,
    SUM(q.view_count) AS total_views
  FROM all_associations a
  JOIN questions q
    ON q.question_id = a.question_id
  GROUP BY a.user_id
)

-- Top 10 users by aggregated view count
SELECT
  u.id           AS user_id,
  u.display_name,
  user_views.total_views
FROM user_views
LEFT JOIN `bigquery-public-data.stackoverflow.users` u
       ON u.id = user_views.user_id
ORDER BY
  total_views DESC,
  user_id
LIMIT 10;
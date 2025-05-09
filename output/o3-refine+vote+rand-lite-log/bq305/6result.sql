-- Top 10 users by total views of questions they are “associated” with
WITH answer_stats AS (
  SELECT
    id,
    parent_id                 AS question_id,
    owner_user_id             AS user_id,
    score,
    ROW_NUMBER() OVER (PARTITION BY parent_id
                       ORDER BY score DESC, id ASC)          AS score_rank,
    SUM(score)  OVER (PARTITION BY parent_id)                AS total_question_score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE parent_id IS NOT NULL
),
-- answers that make their owners associated with the question
qualifying_answers AS (
  SELECT
    question_id,
    user_id
  FROM answer_stats
  WHERE user_id IS NOT NULL
    AND (
         score > 5                                            -- high‑scoring answer
      OR (score > 0 AND score >= 0.20 * total_question_score) -- ≥20 % of total answer score
      OR score_rank <= 3                                      -- in top‑3 answers
    )
),
-- owners of accepted answers
accepted_answers AS (
  SELECT
    q.id        AS question_id,
    a.owner_user_id AS user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  JOIN `bigquery-public-data.stackoverflow.posts_answers`  a
       ON a.id = q.accepted_answer_id
  WHERE q.accepted_answer_id IS NOT NULL
    AND a.owner_user_id IS NOT NULL
),
-- owners of the questions themselves
question_owners AS (
  SELECT
    id   AS question_id,
    owner_user_id AS user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id IS NOT NULL
),
-- union of all (question,user) associations, de‑duplicated
all_associations AS (
  SELECT DISTINCT question_id, user_id FROM question_owners
  UNION DISTINCT
  SELECT DISTINCT question_id, user_id FROM accepted_answers
  UNION DISTINCT
  SELECT DISTINCT question_id, user_id FROM qualifying_answers
),
-- sum of view counts of associated questions per user
user_view_totals AS (
  SELECT
    a.user_id,
    SUM(COALESCE(q.view_count,0)) AS total_views
  FROM all_associations a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
       ON q.id = a.question_id
  GROUP BY a.user_id
)
SELECT
  u.id            AS user_id,
  u.display_name,
  t.total_views
FROM user_view_totals t
JOIN `bigquery-public-data.stackoverflow.users` u
     ON u.id = t.user_id
ORDER BY t.total_views DESC, user_id
LIMIT 10;
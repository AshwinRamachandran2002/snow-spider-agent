WITH
-- owners of each question
question_owners AS (
  SELECT
    id            AS question_id,
    owner_user_id AS user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id IS NOT NULL
),

-- owners of the accepted answer for each question
accepted_answer_owners AS (
  SELECT
    q.id            AS question_id,
    a.owner_user_id AS user_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN `bigquery-public-data.stackoverflow.posts_answers`   AS a
    ON q.accepted_answer_id = a.id
  WHERE a.owner_user_id IS NOT NULL
),

-- total answer score per question
answer_totals AS (
  SELECT
    parent_id                AS question_id,
    SUM(IFNULL(score,0))     AS total_score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),

-- answers ranked by score within each question
ranked_answers AS (
  SELECT
    parent_id                AS question_id,
    id                       AS answer_id,
    owner_user_id            AS user_id,
    IFNULL(score,0)          AS score,
    DENSE_RANK() OVER (
      PARTITION BY parent_id
      ORDER BY IFNULL(score,0) DESC
    )                        AS rank_in_question
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL
),

-- answers satisfying any of the three score‑based rules
qualified_answer_owners AS (
  SELECT
    r.question_id,
    r.user_id
  FROM ranked_answers AS r
  JOIN answer_totals  AS t
    ON r.question_id = t.question_id
  WHERE r.score > 5
     OR (r.score > 0 AND r.score > 0.20 * t.total_score)
     OR r.rank_in_question <= 3
),

-- all (question, user) associations, deduplicated
all_associations AS (
  SELECT * FROM question_owners
  UNION DISTINCT
  SELECT * FROM accepted_answer_owners
  UNION DISTINCT
  SELECT * FROM qualified_answer_owners
),

-- combined view count per user
user_view_sums AS (
  SELECT
    a.user_id,
    SUM(IFNULL(q.view_count,0)) AS combined_view_count
  FROM all_associations AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.id = a.question_id
  GROUP BY a.user_id
)

-- final result
SELECT
  u.id               AS user_id,
  u.display_name     AS user_display_name,
  user_view_sums.combined_view_count
FROM user_view_sums
JOIN `bigquery-public-data.stackoverflow.users` AS u
  ON u.id = user_view_sums.user_id
ORDER BY user_view_sums.combined_view_count DESC, user_id
LIMIT 10;
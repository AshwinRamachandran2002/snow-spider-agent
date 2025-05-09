WITH question_data AS (
  SELECT
    id                             AS question_id,
    owner_user_id                  AS asker_id,
    view_count,
    accepted_answer_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE view_count IS NOT NULL            -- keep questions with a view count
),
total_scores AS (
  SELECT
    parent_id                       AS question_id,
    SUM(score)                      AS total_answer_score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  GROUP BY parent_id
),

-- answers that satisfy any of the first three rules
answer_associations AS (
  SELECT
    a.parent_id                     AS question_id,
    a.owner_user_id                 AS user_id
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  JOIN question_data  q ON q.question_id = a.parent_id
  JOIN total_scores   t ON t.question_id = a.parent_id
  WHERE a.owner_user_id IS NOT NULL
    AND (
         a.id = q.accepted_answer_id                 -- accepted answer
         OR a.score > 5                              -- score > 5
         OR ( a.score > 0 AND a.score > 0.20 * t.total_answer_score )  -- > 20 % of total
        )
),

-- owners of the three highest-scoring answers for every question
top3_answerers AS (
  SELECT question_id, user_id
  FROM (
    SELECT
      parent_id                  AS question_id,
      owner_user_id              AS user_id,
      RANK() OVER(PARTITION BY parent_id ORDER BY score DESC) AS rnk
    FROM `bigquery-public-data.stackoverflow.posts_answers`
    WHERE owner_user_id IS NOT NULL
  )
  WHERE rnk <= 3
),

-- question owners
question_owners AS (
  SELECT question_id, asker_id AS user_id
  FROM   question_data
  WHERE  asker_id IS NOT NULL
),

-- union of all association rules
all_associations AS (
  SELECT * FROM question_owners
  UNION DISTINCT
  SELECT * FROM answer_associations
  UNION DISTINCT
  SELECT * FROM top3_answerers
),

-- aggregate total question views per user
user_totals AS (
  SELECT
    a.user_id,
    SUM(q.view_count) AS total_views
  FROM all_associations a
  JOIN question_data  q ON q.question_id = a.question_id
  GROUP BY a.user_id
)

-- top 10 users with the highest combined view counts
SELECT
  u.id            AS user_id,
  u.display_name,
  t.total_views
FROM user_totals t
JOIN `bigquery-public-data.stackoverflow.users` u
  ON u.id = t.user_id
ORDER BY t.total_views DESC
LIMIT 10;
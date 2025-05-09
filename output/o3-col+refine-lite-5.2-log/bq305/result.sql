WITH
-- questions that have a view‑count
questions AS (
  SELECT
    id               AS question_id,
    owner_user_id,
    view_count,
    accepted_answer_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE view_count IS NOT NULL
),

-- every answer
answers AS (
  SELECT
    id           AS answer_id,
    parent_id    AS question_id,
    owner_user_id,
    score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
),

-- owners of accepted answers
accepted AS (
  SELECT
    q.question_id,
    a.owner_user_id
  FROM   questions q
  JOIN   answers   a
    ON   q.accepted_answer_id = a.answer_id
),

-- answers whose score is greater than 5
high_score AS (
  SELECT
    question_id,
    owner_user_id
  FROM answers
  WHERE score > 5
),

-- total score of all answers per question
totals AS (
  SELECT
    question_id,
    SUM(score) AS total_score
  FROM answers
  GROUP BY question_id
),

-- answers whose score is positive and > 20 % of the total answer‑scores
relative_score AS (
  SELECT
    a.question_id,
    a.owner_user_id
  FROM answers a
  JOIN totals  t USING (question_id)
  WHERE a.score > 0
    AND a.score > 0.20 * t.total_score
),

-- the three highest‑scoring answers for each question
top_three AS (
  SELECT
    question_id,
    owner_user_id
  FROM (
    SELECT
      question_id,
      owner_user_id,
      ROW_NUMBER() OVER (PARTITION BY question_id
                         ORDER BY score DESC, answer_id) AS rn
    FROM answers
  )
  WHERE rn <= 3
),

-- every (question id, user id) association produced by the five rules
associations AS (
  SELECT question_id, owner_user_id FROM questions          -- the asker
  UNION DISTINCT
  SELECT * FROM accepted
  UNION DISTINCT
  SELECT * FROM high_score
  UNION DISTINCT
  SELECT * FROM relative_score
  UNION DISTINCT
  SELECT * FROM top_three
),

-- discard rows where the user is anonymous / deleted
associations_clean AS (
  SELECT *
  FROM   associations
  WHERE  owner_user_id IS NOT NULL
),

-- sum of views of all associated questions per user
user_totals AS (
  SELECT
    a.owner_user_id                 AS user_id,
    SUM(q.view_count)               AS combined_view_count
  FROM associations_clean a
  JOIN questions         q
    ON a.question_id = q.question_id
  GROUP BY user_id
)

-- final result: top 10 users
SELECT
  u.id            AS user_id,
  u.display_name,
  t.combined_view_count
FROM   user_totals t
LEFT JOIN `bigquery-public-data.stackoverflow.users` u
       ON u.id = t.user_id
ORDER BY combined_view_count DESC
LIMIT 10;
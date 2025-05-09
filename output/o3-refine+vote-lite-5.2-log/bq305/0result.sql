-- top 10 users whose associated questions (see criteria) have the largest
-- combined view_count
WITH
-- answers, limited to those that have an owner
answers AS (
  SELECT
    id,
    parent_id               AS question_id,
    owner_user_id           AS user_id,
    IFNULL(score,0)         AS score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id IS NOT NULL
),

-- questions with their basic data, view_count defaulted to 0
questions AS (
  SELECT
    id                      AS question_id,
    owner_user_id           AS asker_id,
    accepted_answer_id,
    IFNULL(view_count,0)    AS view_count
  FROM `bigquery-public-data.stackoverflow.posts_questions`
),

-- total answer score per question (needed for 20 % rule)
answer_totals AS (
  SELECT
    question_id,
    SUM(score) AS total_score
  FROM answers
  GROUP BY question_id
),

-- rank answers by score per question (needed for “top‑3 answers” rule)
ranked_answers AS (
  SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY question_id
                       ORDER BY score DESC, id) AS rn
  FROM answers a
),

-- gather every (question,user) pair that satisfies *any* association rule
associated AS (
  -- 1. question owner
  SELECT q.question_id, q.asker_id AS user_id
  FROM questions q
  WHERE q.asker_id IS NOT NULL

  UNION DISTINCT

  -- 2. owner of accepted answer
  SELECT q.question_id, a.user_id
  FROM questions q
  JOIN answers  a ON a.id = q.accepted_answer_id

  UNION DISTINCT

  -- 3. answers with score > 5
  SELECT question_id, user_id
  FROM answers
  WHERE score > 5

  UNION DISTINCT

  -- 4. answers whose score > 0 and > 20 % of total answer score
  SELECT a.question_id, a.user_id
  FROM answers        a
  JOIN answer_totals t USING (question_id)
  WHERE a.score > 0
    AND a.score > 0.20 * t.total_score

  UNION DISTINCT

  -- 5. owners of the top‑3 highest‑scoring answers for the question
  SELECT question_id, user_id
  FROM ranked_answers
  WHERE rn <= 3
),

-- add each question's view_count to every associated user
user_views AS (
  SELECT
    assoc.user_id,
    q.view_count
  FROM associated assoc
  JOIN questions  q USING (question_id)
)

SELECT
  u.id            AS user_id,
  u.display_name,
  SUM(view_count) AS total_question_views
FROM user_views v
JOIN `bigquery-public-data.stackoverflow.users` u
  ON u.id = v.user_id
GROUP BY user_id, display_name
ORDER BY total_question_views DESC
LIMIT 10;
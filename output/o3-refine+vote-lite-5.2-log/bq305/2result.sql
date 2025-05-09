-- top 10 users by combined view counts of questions they are “associated” with
WITH
-- answers with useful fields
answer_data AS (
  SELECT
    id               AS answer_id,
    parent_id        AS question_id,
    owner_user_id    AS user_id,
    score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE parent_id IS NOT NULL
        AND owner_user_id IS NOT NULL
),
-- questions with needed fields
question_data AS (
  SELECT
    id               AS question_id,
    owner_user_id    AS asker_user_id,
    accepted_answer_id,
    SAFE_CAST(view_count AS INT64) AS view_count          -- view_count is INT64 already, SAFE_CAST for safety
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE view_count IS NOT NULL
        AND owner_user_id IS NOT NULL
),
-- total answer score per question
total_scores AS (
  SELECT
    question_id,
    SUM(score) AS total_score
  FROM answer_data
  GROUP BY question_id
),
-- rank answers by score within each question
ranked_answers AS (
  SELECT
    question_id,
    answer_id,
    user_id,
    score,
    ROW_NUMBER() OVER (PARTITION BY question_id ORDER BY score DESC, answer_id) AS rnk
  FROM answer_data
),
-- gather every (question,user) pair that meets *any* association rule
associated AS (
  SELECT DISTINCT question_id, user_id FROM (
    -- 1. question owner
    SELECT question_id, asker_user_id AS user_id
    FROM question_data

    UNION ALL
    -- 2. accepted answerer
    SELECT q.question_id, a.user_id
    FROM question_data q
    JOIN answer_data a
      ON a.answer_id = q.accepted_answer_id

    UNION ALL
    -- 3. answer score > 5
    SELECT question_id, user_id
    FROM answer_data
    WHERE score > 5

    UNION ALL
    -- 4. answer score > 20 % of total answer score (and >0)
    SELECT a.question_id, a.user_id
    FROM answer_data a
    JOIN total_scores t
      ON t.question_id = a.question_id
    WHERE a.score > 0
      AND a.score > 0.2 * t.total_score

    UNION ALL
    -- 5. top‑three answers by score
    SELECT question_id, user_id
    FROM ranked_answers
    WHERE rnk <= 3
  )
)
-- sum question view_counts for each associated user and take the top 10
SELECT
  user_id,
  SUM(q.view_count) AS total_view_count
FROM associated s
JOIN question_data q
  ON q.question_id = s.question_id
GROUP BY user_id
ORDER BY total_view_count DESC
LIMIT 10;
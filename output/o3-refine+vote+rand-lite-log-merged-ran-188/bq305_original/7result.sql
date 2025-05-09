WITH questions AS (
  SELECT
    id                                                        AS question_id,
    owner_user_id,
    accepted_answer_id,
    COALESCE(view_count,0)                                    AS view_count
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE view_count IS NOT NULL
),
answers AS (
  SELECT
    id                       AS answer_id,
    parent_id                AS question_id,
    owner_user_id,
    score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
),
total_scores AS (                      -- total answer score for each question
  SELECT
    question_id,
    SUM(score)               AS total_score
  FROM answers
  GROUP BY question_id
),
answers_ranked AS (                    -- rank answers per question by score
  SELECT
    a.*,
    ROW_NUMBER() OVER (PARTITION BY question_id
                       ORDER BY score DESC, answer_id) AS rn
  FROM answers a
),
qualified_answers AS (                 -- answers that meet any association rule
  SELECT
    ar.question_id,
    ar.owner_user_id                  AS user_id
  FROM answers_ranked ar
  LEFT JOIN questions    q  ON q.question_id = ar.question_id
  LEFT JOIN total_scores ts ON ts.question_id = ar.question_id
  WHERE ar.owner_user_id IS NOT NULL
    AND (
         ar.answer_id = q.accepted_answer_id            -- accepted answer
      OR ar.score > 5                                   -- score > 5
      OR (ar.score > 0 AND ar.score > 0.2 * ts.total_score) -- >20 % of total
      OR ar.rn <= 3                                     -- in top‑3 scores
    )
),
question_owners AS (                -- owners of questions
  SELECT
    question_id,
    owner_user_id AS user_id
  FROM questions
  WHERE owner_user_id IS NOT NULL
),
user_question_assoc AS (            -- one row per user‑question association
  SELECT DISTINCT user_id, question_id
  FROM (
        SELECT * FROM qualified_answers
        UNION ALL
        SELECT * FROM question_owners
  )
),
user_views AS (                      -- sum of view counts per user
  SELECT
    uqa.user_id,
    SUM(q.view_count) AS total_views
  FROM user_question_assoc uqa
  JOIN questions q ON q.question_id = uqa.question_id
  GROUP BY uqa.user_id
)
SELECT
  uv.user_id,
  COALESCE(u.display_name,
           CONCAT('[user ', CAST(uv.user_id AS STRING), ']')) AS display_name,
  uv.total_views
FROM user_views uv
LEFT JOIN `bigquery-public-data.stackoverflow.users` u
       ON u.id = uv.user_id
ORDER BY uv.total_views DESC, uv.user_id
LIMIT 10;
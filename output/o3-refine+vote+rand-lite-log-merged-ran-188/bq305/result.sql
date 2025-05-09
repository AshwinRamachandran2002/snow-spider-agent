WITH questions AS (
  SELECT
    id                           AS question_id,
    owner_user_id                AS q_owner,
    view_count,
    accepted_answer_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE view_count IS NOT NULL
),
answers AS (
  SELECT
    id                           AS answer_id,
    parent_id                    AS question_id,
    owner_user_id                AS a_owner,
    score
  FROM `bigquery-public-data.stackoverflow.posts_answers`
),
total_answer_scores AS (
  SELECT
    question_id,
    SUM(IFNULL(score,0))         AS total_score
  FROM answers
  GROUP BY question_id
),
ranked_answers AS (
  SELECT
    a.*,
    tas.total_score,
    ROW_NUMBER() OVER (PARTITION BY a.question_id
                       ORDER BY a.score DESC, a.answer_id) AS rn
  FROM answers a
  JOIN total_answer_scores tas USING (question_id)
),
associated_pairs AS (
  SELECT DISTINCT question_id, user_id
  FROM (
        -- 1) question owner
        SELECT question_id, q_owner AS user_id
        FROM questions
        WHERE q_owner IS NOT NULL
        
        UNION ALL
        
        -- 2) owner of accepted answer
        SELECT q.question_id, a.a_owner
        FROM questions q
        JOIN answers   a ON q.accepted_answer_id = a.answer_id
        WHERE a.a_owner IS NOT NULL
        
        UNION ALL
        
        -- 3) answers with score > 5
        SELECT question_id, a_owner
        FROM answers
        WHERE score > 5
          AND a_owner IS NOT NULL
        
        UNION ALL
        
        -- 4) answers whose score > 20% of total answer score (and > 0)
        SELECT question_id, a_owner
        FROM ranked_answers
        WHERE score > 0
          AND score > 0.2 * total_score
          AND a_owner IS NOT NULL
        
        UNION ALL
        
        -- 5) top-3 highest-scoring answers per question
        SELECT question_id, a_owner
        FROM ranked_answers
        WHERE rn <= 3
          AND a_owner IS NOT NULL
  )
),
user_view_totals AS (
  SELECT
    user_id,
    SUM(view_count) AS total_views
  FROM associated_pairs
  JOIN questions USING (question_id)
  GROUP BY user_id
)
SELECT
  user_id,
  total_views
FROM user_view_totals
ORDER BY total_views DESC
LIMIT 10;
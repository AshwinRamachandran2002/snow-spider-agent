WITH
  owner_questions AS (
    SELECT DISTINCT owner_user_id, id AS question_id
    FROM `bigquery-public-data.stackoverflow.posts_questions`
    WHERE owner_user_id IS NOT NULL
  ),
  accepted_answers AS (
    SELECT DISTINCT pa.owner_user_id, pq.id AS question_id
    FROM `bigquery-public-data.stackoverflow.posts_questions` AS pq
    JOIN `bigquery-public-data.stackoverflow.posts_answers` AS pa
      ON pq.accepted_answer_id = pa.id
    WHERE pa.owner_user_id IS NOT NULL
  ),
  high_score_answers AS (
    SELECT DISTINCT owner_user_id, parent_id AS question_id
    FROM `bigquery-public-data.stackoverflow.posts_answers`
    WHERE score > 5 AND owner_user_id IS NOT NULL
  ),
  top_three_answers AS (
    SELECT owner_user_id, parent_id AS question_id
    FROM (
      SELECT *,
        ROW_NUMBER() OVER (PARTITION BY parent_id ORDER BY score DESC) AS rn
      FROM `bigquery-public-data.stackoverflow.posts_answers`
      WHERE owner_user_id IS NOT NULL
    )
    WHERE rn <= 3
  ),
  high_percentage_answers AS (
    SELECT DISTINCT pa.owner_user_id, pa.parent_id AS question_id
    FROM `bigquery-public-data.stackoverflow.posts_answers` AS pa
    JOIN (
      SELECT parent_id, SUM(score) AS total_score
      FROM `bigquery-public-data.stackoverflow.posts_answers`
      GROUP BY parent_id
    ) AS ts
      ON pa.parent_id = ts.parent_id
    WHERE pa.score > 0.2 * ts.total_score AND pa.owner_user_id IS NOT NULL
  ),
  all_users_questions AS (
    SELECT owner_user_id, question_id FROM owner_questions
    UNION ALL
    SELECT owner_user_id, question_id FROM accepted_answers
    UNION ALL
    SELECT owner_user_id, question_id FROM high_score_answers
    UNION ALL
    SELECT owner_user_id, question_id FROM top_three_answers
    UNION ALL
    SELECT owner_user_id, question_id FROM high_percentage_answers
  )
SELECT
  auq.owner_user_id AS User_ID,
  SUM(q.view_count) AS Total_View_Count
FROM (
  SELECT DISTINCT owner_user_id, question_id
  FROM all_users_questions
) auq
JOIN `bigquery-public-data.stackoverflow.posts_questions` q
  ON auq.question_id = q.id
WHERE q.view_count IS NOT NULL
GROUP BY auq.owner_user_id
ORDER BY Total_View_Count DESC
LIMIT 10
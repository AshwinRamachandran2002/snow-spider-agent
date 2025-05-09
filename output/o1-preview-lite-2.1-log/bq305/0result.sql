WITH user_question_pairs AS (

  -- Users who own a question
  SELECT owner_user_id AS user_id, id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id IS NOT NULL

  UNION ALL

  -- Users who provided an accepted answer
  SELECT a.owner_user_id AS user_id, q.id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` a
    ON a.id = q.accepted_answer_id
  WHERE a.owner_user_id IS NOT NULL
    AND q.accepted_answer_id IS NOT NULL

  UNION ALL

  -- Users who have answers with a score above 5
  SELECT owner_user_id AS user_id, parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE score > 5
    AND owner_user_id IS NOT NULL
    AND parent_id IS NOT NULL

  UNION ALL

  -- Users who rank in the top 3 answers for a question
  SELECT user_id, question_id FROM (
    SELECT owner_user_id AS user_id, parent_id AS question_id,
           ROW_NUMBER() OVER (PARTITION BY parent_id ORDER BY score DESC) AS rank
    FROM `bigquery-public-data.stackoverflow.posts_answers`
    WHERE owner_user_id IS NOT NULL
      AND parent_id IS NOT NULL
  )
  WHERE rank <= 3

  UNION ALL

  -- Users who have an answer with a score over 20% of the total answer score for that question
  SELECT a.owner_user_id AS user_id, a.parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers` a
  JOIN (
    SELECT parent_id AS question_id, SUM(score) AS total_score
    FROM `bigquery-public-data.stackoverflow.posts_answers`
    WHERE parent_id IS NOT NULL
    GROUP BY parent_id
  ) t ON a.parent_id = t.question_id
  WHERE a.owner_user_id IS NOT NULL
    AND a.score > 0.2 * t.total_score

)

SELECT uq.user_id AS User_ID, SUM(q.view_count) AS Total_View_Count
FROM (
  SELECT DISTINCT user_id, question_id
  FROM user_question_pairs
) uq
JOIN `bigquery-public-data.stackoverflow.posts_questions` q
  ON uq.question_id = q.id
WHERE q.view_count IS NOT NULL
GROUP BY uq.user_id
ORDER BY Total_View_Count DESC
LIMIT 10;
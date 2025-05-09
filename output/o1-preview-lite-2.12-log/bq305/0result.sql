SELECT
  user_id,
  SUM(view_count) AS combined_view_count
FROM (
  -- Combine all associations and remove duplicates
  SELECT DISTINCT user_id, question_id, view_count FROM (

    -- Users who own the question
    SELECT q.owner_user_id AS user_id, q.id AS question_id, q.view_count
    FROM `bigquery-public-data.stackoverflow.posts_questions` q
    WHERE q.owner_user_id IS NOT NULL

    UNION ALL

    -- Users whose answer is the accepted answer
    SELECT a.owner_user_id AS user_id, q.id AS question_id, q.view_count
    FROM `bigquery-public-data.stackoverflow.posts_questions` q
    JOIN `bigquery-public-data.stackoverflow.posts_answers` a
      ON q.accepted_answer_id = a.id
    WHERE a.owner_user_id IS NOT NULL

    UNION ALL

    -- Users whose answer's score is greater than 5
    SELECT a.owner_user_id AS user_id, q.id AS question_id, q.view_count
    FROM `bigquery-public-data.stackoverflow.posts_questions` q
    JOIN `bigquery-public-data.stackoverflow.posts_answers` a
      ON a.parent_id = q.id
    WHERE a.score > 5 AND a.owner_user_id IS NOT NULL

    UNION ALL

    -- Users whose answer's score exceeds 20% of total answer scores for that question (and is above 0)
    SELECT a.owner_user_id AS user_id, q.id AS question_id, q.view_count
    FROM `bigquery-public-data.stackoverflow.posts_questions` q
    JOIN `bigquery-public-data.stackoverflow.posts_answers` a
      ON a.parent_id = q.id
    JOIN (
      SELECT parent_id, SUM(score) AS total_score
      FROM `bigquery-public-data.stackoverflow.posts_answers`
      GROUP BY parent_id
    ) ts ON a.parent_id = ts.parent_id
    WHERE a.score > 0 AND a.score > 0.2 * ts.total_score AND a.owner_user_id IS NOT NULL

    UNION ALL

    -- Users whose answer is among the top three highest-scoring answers for that question
    SELECT a.owner_user_id AS user_id, q.id AS question_id, q.view_count
    FROM `bigquery-public-data.stackoverflow.posts_questions` q
    JOIN (
      SELECT parent_id AS question_id, owner_user_id,
        ROW_NUMBER() OVER (PARTITION BY parent_id ORDER BY score DESC) AS rn
      FROM `bigquery-public-data.stackoverflow.posts_answers`
      WHERE owner_user_id IS NOT NULL
    ) a ON q.id = a.question_id
    WHERE a.rn <= 3
  )
) assoc
GROUP BY user_id
ORDER BY combined_view_count DESC
LIMIT 10;
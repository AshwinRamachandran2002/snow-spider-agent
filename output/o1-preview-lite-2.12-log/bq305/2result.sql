WITH user_question_associations AS (
  -- Condition 1: Users who own the question
  SELECT owner_user_id AS user_id, id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id IS NOT NULL

  UNION DISTINCT

  -- Condition 2: Users whose answer is the accepted answer
  SELECT a.owner_user_id AS user_id, q.id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
  ON q.accepted_answer_id = a.id
  WHERE a.owner_user_id IS NOT NULL

  UNION DISTINCT

  -- Condition 3: Users whose answer has score > 5
  SELECT owner_user_id AS user_id, parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE score > 5 AND owner_user_id IS NOT NULL

  UNION DISTINCT

  -- Condition 4: Users whose answer's score exceeds 20% of total answer scores for that question (and is above 0)
  SELECT a.owner_user_id AS user_id, a.parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
  JOIN (
    SELECT parent_id AS question_id, SUM(score) AS total_score
    FROM `bigquery-public-data.stackoverflow.posts_answers`
    GROUP BY parent_id
    HAVING SUM(score) > 0
  ) AS tas ON a.parent_id = tas.question_id
  WHERE a.score > 0 AND a.score > 0.2 * tas.total_score AND a.owner_user_id IS NOT NULL

  UNION DISTINCT

  -- Condition 5: Users whose answer is among the top three highest-scoring answers for that question
  SELECT ranked_answers.owner_user_id AS user_id, ranked_answers.parent_id AS question_id
  FROM (
    SELECT a.parent_id, a.owner_user_id, a.score,
           ROW_NUMBER() OVER (PARTITION BY a.parent_id ORDER BY a.score DESC) AS rank
    FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
    WHERE a.owner_user_id IS NOT NULL
  ) AS ranked_answers
  WHERE rank <= 3
)

SELECT uqa.user_id, SUM(q.view_count) AS combined_view_count
FROM user_question_associations AS uqa
JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q ON uqa.question_id = q.id
GROUP BY uqa.user_id
ORDER BY combined_view_count DESC
LIMIT 10;
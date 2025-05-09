WITH user_questions AS (
  SELECT owner_user_id AS user_id, id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id IS NOT NULL
),
accepted_answers AS (
  SELECT a.owner_user_id AS user_id, q.id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.accepted_answer_id = a.id
  WHERE a.owner_user_id IS NOT NULL AND q.accepted_answer_id IS NOT NULL
),
high_score_answers AS (
  SELECT a.owner_user_id AS user_id, a.parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
  WHERE a.owner_user_id IS NOT NULL AND a.score > 5
),
top_3_answers AS (
  SELECT user_id, question_id
  FROM (
    SELECT a.owner_user_id AS user_id, a.parent_id AS question_id,
           ROW_NUMBER() OVER (PARTITION BY a.parent_id ORDER BY a.score DESC) AS rank
    FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
    WHERE a.owner_user_id IS NOT NULL
  )
  WHERE rank <= 3
),
score_20_percent_answers AS (
  SELECT a.owner_user_id AS user_id, a.parent_id AS question_id
  FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
  JOIN (
    SELECT parent_id AS question_id, SUM(score) AS total_score
    FROM `bigquery-public-data.stackoverflow.posts_answers`
    GROUP BY parent_id
  ) AS ts ON a.parent_id = ts.question_id
  WHERE a.owner_user_id IS NOT NULL AND ts.total_score > 0 AND a.score > 0.2 * ts.total_score
)
SELECT user_id, SUM(q.view_count) AS total_view_count
FROM (
  SELECT DISTINCT user_id, question_id FROM user_questions
  UNION DISTINCT
  SELECT DISTINCT user_id, question_id FROM accepted_answers
  UNION DISTINCT
  SELECT DISTINCT user_id, question_id FROM high_score_answers
  UNION DISTINCT
  SELECT DISTINCT user_id, question_id FROM top_3_answers
  UNION DISTINCT
  SELECT DISTINCT user_id, question_id FROM score_20_percent_answers
) AS uq
JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
  ON uq.question_id = q.id
GROUP BY user_id
ORDER BY total_view_count DESC
LIMIT 10
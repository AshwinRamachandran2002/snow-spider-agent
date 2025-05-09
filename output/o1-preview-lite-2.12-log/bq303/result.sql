SELECT user_id, tags
FROM (
  -- Questions authored by users
  SELECT pq.owner_user_id AS user_id, pq.tags, pq.creation_date AS contribution_date
  FROM `bigquery-public-data.stackoverflow.posts_questions` pq

  UNION ALL

  -- Answers authored by users
  SELECT pa.owner_user_id AS user_id, pq.tags, pa.creation_date AS contribution_date
  FROM `bigquery-public-data.stackoverflow.posts_answers` pa
  JOIN `bigquery-public-data.stackoverflow.posts_questions` pq ON pa.parent_id = pq.id

  UNION ALL

  -- Comments on questions
  SELECT c.user_id AS user_id, pq.tags, c.creation_date AS contribution_date
  FROM `bigquery-public-data.stackoverflow.comments` c
  JOIN `bigquery-public-data.stackoverflow.posts_questions` pq ON c.post_id = pq.id

  UNION ALL

  -- Comments on answers
  SELECT c.user_id AS user_id, pq.tags, c.creation_date AS contribution_date
  FROM `bigquery-public-data.stackoverflow.comments` c
  JOIN `bigquery-public-data.stackoverflow.posts_answers` pa ON c.post_id = pa.id
  JOIN `bigquery-public-data.stackoverflow.posts_questions` pq ON pa.parent_id = pq.id
)
WHERE user_id BETWEEN 16712208 AND 18712208
  AND contribution_date >= '2019-07-01' AND contribution_date <= '2019-12-31'
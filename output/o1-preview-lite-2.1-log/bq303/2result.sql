SELECT user_id, tags
FROM (
  -- Questions
  SELECT owner_user_id AS user_id, tags
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id BETWEEN 16712208 AND 18712208
    AND creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND tags IS NOT NULL AND tags != ''

  UNION ALL

  -- Answers
  SELECT owner_user_id AS user_id, tags
  FROM `bigquery-public-data.stackoverflow.posts_answers`
  WHERE owner_user_id BETWEEN 16712208 AND 18712208
    AND creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND tags IS NOT NULL AND tags != ''

  UNION ALL

  -- Comments on Questions
  SELECT c.user_id, q.tags
  FROM `bigquery-public-data.stackoverflow.comments` AS c
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON c.post_id = q.id
  WHERE c.user_id BETWEEN 16712208 AND 18712208
    AND c.creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND q.tags IS NOT NULL AND q.tags != ''

  UNION ALL

  -- Comments on Answers
  SELECT c.user_id, a.tags
  FROM `bigquery-public-data.stackoverflow.comments` AS c
  JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON c.post_id = a.id
  WHERE c.user_id BETWEEN 16712208 AND 18712208
    AND c.creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND a.tags IS NOT NULL AND a.tags != ''
);
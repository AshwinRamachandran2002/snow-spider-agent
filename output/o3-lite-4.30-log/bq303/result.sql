WITH
  questions AS (
    SELECT
      owner_user_id AS user_id,
      tags
    FROM `bigquery-public-data.stackoverflow.posts_questions`
    WHERE creation_date BETWEEN '2019-07-01' AND '2019-12-31 23:59:59'
      AND owner_user_id BETWEEN 16712208 AND 18712208
  ),
  answers AS (
    SELECT
      a.owner_user_id AS user_id,
      q.tags
    FROM `bigquery-public-data.stackoverflow.posts_answers`   AS a
    JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
      ON q.id = a.parent_id
    WHERE a.creation_date BETWEEN '2019-07-01' AND '2019-12-31 23:59:59'
      AND a.owner_user_id BETWEEN 16712208 AND 18712208
  ),
  comments_on_questions AS (
    SELECT
      c.user_id AS user_id,
      q.tags
    FROM `bigquery-public-data.stackoverflow.comments`        AS c
    JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
      ON q.id = c.post_id
    WHERE c.creation_date BETWEEN '2019-07-01' AND '2019-12-31 23:59:59'
      AND c.user_id BETWEEN 16712208 AND 18712208
  ),
  comments_on_answers AS (
    SELECT
      c.user_id AS user_id,
      q.tags
    FROM `bigquery-public-data.stackoverflow.comments`        AS c
    JOIN `bigquery-public-data.stackoverflow.posts_answers`   AS a
      ON a.id = c.post_id
    JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
      ON q.id = a.parent_id
    WHERE c.creation_date BETWEEN '2019-07-01' AND '2019-12-31 23:59:59'
      AND c.user_id BETWEEN 16712208 AND 18712208
  )

SELECT
  user_id,
  tags
FROM (
  SELECT * FROM questions
  UNION ALL
  SELECT * FROM answers
  UNION ALL
  SELECT * FROM comments_on_questions
  UNION ALL
  SELECT * FROM comments_on_answers
);
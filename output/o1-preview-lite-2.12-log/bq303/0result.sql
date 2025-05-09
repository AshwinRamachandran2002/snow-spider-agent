WITH contributions AS (
  SELECT
    q.`owner_user_id` AS user_id,
    q.`id` AS question_id,
    q.`creation_date`
  FROM
    `bigquery-public-data.stackoverflow.posts_questions` AS q

  UNION ALL

  SELECT
    a.`owner_user_id` AS user_id,
    a.`parent_id` AS question_id,
    a.`creation_date`
  FROM
    `bigquery-public-data.stackoverflow.posts_answers` AS a

  UNION ALL

  SELECT
    c.`user_id` AS user_id,
    c.`post_id` AS question_id,
    c.`creation_date`
  FROM
    `bigquery-public-data.stackoverflow.comments` AS c
  JOIN
    `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON c.`post_id` = q.`id`

  UNION ALL

  SELECT
    c.`user_id` AS user_id,
    a.`parent_id` AS question_id,
    c.`creation_date`
  FROM
    `bigquery-public-data.stackoverflow.comments` AS c
  JOIN
    `bigquery-public-data.stackoverflow.posts_answers` AS a
    ON c.`post_id` = a.`id`
)
SELECT
  contributions.`user_id`,
  q.`tags`
FROM
  contributions
JOIN
  `bigquery-public-data.stackoverflow.posts_questions` AS q
  ON contributions.`question_id` = q.`id`
WHERE
  contributions.`user_id` BETWEEN 16712208 AND 18712208
  AND contributions.`creation_date` BETWEEN '2019-07-01' AND '2019-12-31'
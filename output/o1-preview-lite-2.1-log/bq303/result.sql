SELECT
  user_id,
  tags
FROM
(
  SELECT
    `owner_user_id` AS user_id,
    `creation_date`,
    `tags`
  FROM
    `bigquery-public-data.stackoverflow.posts_questions`

  UNION ALL

  SELECT
    a.`owner_user_id` AS user_id,
    a.`creation_date`,
    q.`tags`
  FROM
    `bigquery-public-data.stackoverflow.posts_answers` AS a
  JOIN
    `bigquery-public-data.stackoverflow.posts_questions` AS q
  ON
    a.`parent_id` = q.`id`

  UNION ALL

  SELECT
    c.`user_id` AS user_id,
    c.`creation_date`,
    COALESCE(q.`tags`, q2.`tags`) AS `tags`
  FROM
    `bigquery-public-data.stackoverflow.comments` AS c
  LEFT JOIN
    `bigquery-public-data.stackoverflow.posts_questions` AS q
  ON
    c.`post_id` = q.`id`
  LEFT JOIN
    `bigquery-public-data.stackoverflow.posts_answers` AS a
  ON
    c.`post_id` = a.`id`
  LEFT JOIN
    `bigquery-public-data.stackoverflow.posts_questions` AS q2
  ON
    a.`parent_id` = q2.`id`
)
WHERE
  user_id BETWEEN 16712208 AND 18712208
  AND DATE(`creation_date`) BETWEEN '2019-07-01' AND '2019-12-31';
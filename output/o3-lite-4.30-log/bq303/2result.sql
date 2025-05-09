SELECT
  user_id,
  tags
FROM (
  /* questions authored by the users */
  SELECT
    owner_user_id AS user_id,
    tags,
    creation_date
  FROM `bigquery-public-data.stackoverflow.posts_questions`

  UNION ALL

  /* answers authored by the users – tags taken from the parent question */
  SELECT
    a.owner_user_id AS user_id,
    q.tags,
    a.creation_date
  FROM `bigquery-public-data.stackoverflow.posts_answers`   AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON a.parent_id = q.id

  UNION ALL

  /* comments written directly on questions */
  SELECT
    c.user_id,
    q.tags,
    c.creation_date
  FROM `bigquery-public-data.stackoverflow.comments`        AS c
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON c.post_id = q.id

  UNION ALL

  /* comments written on answers (hop through the answer to reach the question) */
  SELECT
    c.user_id,
    q.tags,
    c.creation_date
  FROM `bigquery-public-data.stackoverflow.comments`        AS c
  JOIN `bigquery-public-data.stackoverflow.posts_answers`    AS a
    ON c.post_id = a.id
  JOIN `bigquery-public-data.stackoverflow.posts_questions`  AS q
    ON a.parent_id = q.id
) AS contributions
WHERE creation_date BETWEEN '2019-07-01' AND '2019-12-31'
  AND user_id BETWEEN 16712208 AND 18712208;
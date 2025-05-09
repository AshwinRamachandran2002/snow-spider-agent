WITH contribs AS (

  /* questions authored in the period */
  SELECT
    owner_user_id AS user_id,
    tags
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE DATE(creation_date) BETWEEN '2019-07-01' AND '2019-12-31'
    AND owner_user_id BETWEEN 16712208 AND 18712208

  UNION ALL

  /* answers authored in the period (join to parent question for its tags) */
  SELECT
    a.owner_user_id AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.posts_answers`   AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.id = a.parent_id
  WHERE DATE(a.creation_date) BETWEEN '2019-07-01' AND '2019-12-31'
    AND a.owner_user_id BETWEEN 16712208 AND 18712208

  UNION ALL

  /* comments made directly on questions */
  SELECT
    c.user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments`        AS c
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.id = c.post_id
  WHERE DATE(c.creation_date) BETWEEN '2019-07-01' AND '2019-12-31'
    AND c.user_id BETWEEN 16712208 AND 18712208

  UNION ALL

  /* comments made on answers (map back to the parent question for its tags) */
  SELECT
    c.user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments`        AS c
  JOIN `bigquery-public-data.stackoverflow.posts_answers`   AS a
    ON a.id = c.post_id
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.id = a.parent_id
  WHERE DATE(c.creation_date) BETWEEN '2019-07-01' AND '2019-12-31'
    AND c.user_id BETWEEN 16712208 AND 18712208
)

SELECT DISTINCT
  user_id,
  tag
FROM contribs
CROSS JOIN UNNEST(SPLIT(tags, '|')) AS tag
WHERE tags IS NOT NULL
ORDER BY user_id, tag;
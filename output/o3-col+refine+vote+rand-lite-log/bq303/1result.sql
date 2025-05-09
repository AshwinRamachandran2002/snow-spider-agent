-- every question, answer, and comment made (2019-07-01‒2019-12-31)
-- by users whose id is between 16 712 208 and 18 712 208,
-- together with the tag string of the *parent* question
SELECT user_id,
       question_tags
FROM (

  -- 1. questions they asked
  SELECT
      q.owner_user_id       AS user_id,
      q.tags                AS question_tags
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE q.owner_user_id BETWEEN 16712208 AND 18712208
    AND q.creation_date BETWEEN '2019-07-01' AND '2019-12-31'

  UNION ALL

  -- 2. answers they posted (join to the parent question for its tags)
  SELECT
      a.owner_user_id       AS user_id,
      q.tags                AS question_tags
  FROM `bigquery-public-data.stackoverflow.posts_answers`   AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
        ON q.id = a.parent_id
  WHERE a.owner_user_id BETWEEN 16712208 AND 18712208
    AND a.creation_date BETWEEN '2019-07-01' AND '2019-12-31'

  UNION ALL

  -- 3. comments they wrote *on questions*
  SELECT
      c.user_id             AS user_id,
      q.tags                AS question_tags
  FROM `bigquery-public-data.stackoverflow.comments`        AS c
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
        ON q.id = c.post_id
  WHERE c.user_id BETWEEN 16712208 AND 18712208
    AND c.creation_date BETWEEN '2019-07-01' AND '2019-12-31'

  UNION ALL

  -- 4. comments they wrote *on answers* (hop answer ➜ question)
  SELECT
      c.user_id             AS user_id,
      q.tags                AS question_tags
  FROM `bigquery-public-data.stackoverflow.comments`        AS c
  JOIN `bigquery-public-data.stackoverflow.posts_answers`   AS a
        ON a.id = c.post_id
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
        ON q.id = a.parent_id
  WHERE c.user_id BETWEEN 16712208 AND 18712208
    AND c.creation_date BETWEEN '2019-07-01' AND '2019-12-31'

);
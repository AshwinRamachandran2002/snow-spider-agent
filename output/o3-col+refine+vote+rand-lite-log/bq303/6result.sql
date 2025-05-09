-- Every contribution (question, answer, comment-on-question, comment-on-answer)
-- made in H2-2019 by users 16 712 208-18 712 208,
-- paired with the tags of the originating question.
WITH
  limits AS (
    SELECT
      16712208 AS min_id,
      18712208 AS max_id,
      TIMESTAMP('2019-07-01') AS start_ts,
      TIMESTAMP('2020-01-01') AS end_ts
  )

SELECT
  user_id,
  tags
FROM (

  /* 1. Questions they authored */
  SELECT
    q.owner_user_id         AS user_id,
    q.tags                  AS tags
  FROM `bigquery-public-data.stackoverflow.posts_questions` q, limits l
  WHERE q.owner_user_id BETWEEN l.min_id AND l.max_id
    AND q.creation_date >= l.start_ts
    AND q.creation_date <  l.end_ts

  UNION ALL

  /* 2. Answers they authored (join to parent question for tags) */
  SELECT
    a.owner_user_id         AS user_id,
    q.tags                  AS tags
  FROM `bigquery-public-data.stackoverflow.posts_answers`   a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.parent_id = q.id, limits l
  WHERE a.owner_user_id BETWEEN l.min_id AND l.max_id
    AND a.creation_date >= l.start_ts
    AND a.creation_date <  l.end_ts

  UNION ALL

  /* 3. Comments left directly on questions */
  SELECT
    c.user_id               AS user_id,
    q.tags                  AS tags
  FROM `bigquery-public-data.stackoverflow.comments`        c
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON c.post_id = q.id, limits l
  WHERE c.user_id BETWEEN l.min_id AND l.max_id
    AND c.creation_date >= l.start_ts
    AND c.creation_date <  l.end_ts

  UNION ALL

  /* 4. Comments left on answers (hop answer → question for tags) */
  SELECT
    c.user_id               AS user_id,
    q.tags                  AS tags
  FROM `bigquery-public-data.stackoverflow.comments`        c
  JOIN `bigquery-public-data.stackoverflow.posts_answers`   a
    ON c.post_id = a.id
  JOIN `bigquery-public-data.stackoverflow.posts_questions` q
    ON a.parent_id = q.id, limits l
  WHERE c.user_id BETWEEN l.min_id AND l.max_id
    AND c.creation_date >= l.start_ts
    AND c.creation_date <  l.end_ts
)

ORDER BY user_id;
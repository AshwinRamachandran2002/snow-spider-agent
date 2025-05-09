-- users’ contributions (questions, answers, comments)   
-- between 2019‑07‑01 and 2019‑12‑31, restricted to user ids
-- from 16 712 208 through 18 712 208, with the tags of the
-- corresponding parent question.

WITH
  limits AS (
    SELECT
      TIMESTAMP('2019-07-01') AS start_dt ,
      TIMESTAMP('2020-01-01') AS end_dt          -- exclusive upper bound
  ),

-- questions written by the users
  q_posts AS (
    SELECT
      pq.owner_user_id AS user_id ,
      pq.tags
    FROM `bigquery-public-data.stackoverflow.posts_questions` AS pq
    JOIN limits l
      ON pq.creation_date BETWEEN l.start_dt AND l.end_dt
    WHERE pq.owner_user_id BETWEEN 16712208 AND 18712208
  ),

-- answers written by the users (join to parent question for tags)
  a_posts AS (
    SELECT
      pa.owner_user_id AS user_id ,
      q.tags
    FROM `bigquery-public-data.stackoverflow.posts_answers`   AS pa
    JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
      ON pa.parent_id = q.id
    JOIN limits l
      ON pa.creation_date BETWEEN l.start_dt AND l.end_dt
    WHERE pa.owner_user_id BETWEEN 16712208 AND 18712208
  ),

-- comments on questions
  c_on_q AS (
    SELECT
      c.user_id ,
      q.tags
    FROM `bigquery-public-data.stackoverflow.comments`        AS c
    JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
      ON c.post_id = q.id
    JOIN limits l
      ON c.creation_date BETWEEN l.start_dt AND l.end_dt
    WHERE c.user_id BETWEEN 16712208 AND 18712208
  ),

-- comments on answers (need two‑step join to reach the question)
  c_on_a AS (
    SELECT
      c.user_id ,
      q.tags
    FROM `bigquery-public-data.stackoverflow.comments`        AS c
    JOIN `bigquery-public-data.stackoverflow.posts_answers`   AS a
      ON c.post_id = a.id
    JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
      ON a.parent_id = q.id
    JOIN limits l
      ON c.creation_date BETWEEN l.start_dt AND l.end_dt
    WHERE c.user_id BETWEEN 16712208 AND 18712208
  )

-- union all contributions
SELECT user_id , tags
FROM (
  SELECT * FROM q_posts
  UNION ALL
  SELECT * FROM a_posts
  UNION ALL
  SELECT * FROM c_on_q
  UNION ALL
  SELECT * FROM c_on_a
)
ORDER BY user_id;
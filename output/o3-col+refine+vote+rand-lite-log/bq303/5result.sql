--  User–tag pairs for every contribution made between 2019-07-01 and 2019-12-31
--  by Stack Overflow users whose ids are in the range 16 712 208 – 18 712 208.
WITH
/* -------------------------------------------------------------------------- */
/* configurable boundaries                                                    */
b AS (
  SELECT
    16712208 AS min_uid,
    18712208 AS max_uid,
    TIMESTAMP('2019-07-01') AS from_ts,          -- inclusive
    TIMESTAMP('2020-01-01') AS to_ts             -- exclusive (= 2019-12-31 23:59:59)
),

/* -------------------------------------------------------------------------- */
/* questions written by the users                                             */
q_contrib AS (
  SELECT
    q.owner_user_id AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  CROSS JOIN b
  WHERE q.owner_user_id BETWEEN b.min_uid AND b.max_uid
    AND q.creation_date >= b.from_ts
    AND q.creation_date <  b.to_ts
),

/* -------------------------------------------------------------------------- */
/* answers written by the users – attach parent-question tags                 */
a_contrib AS (
  SELECT
    a.owner_user_id AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.posts_answers`   AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.id = a.parent_id
  CROSS JOIN b
  WHERE a.owner_user_id BETWEEN b.min_uid AND b.max_uid
    AND a.creation_date >= b.from_ts
    AND a.creation_date <  b.to_ts
),

/* -------------------------------------------------------------------------- */
/* comments the users left directly on questions                              */
c_on_q AS (
  SELECT
    c.user_id AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments`        AS c
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.id = c.post_id
  CROSS JOIN b
  WHERE c.user_id BETWEEN b.min_uid AND b.max_uid
    AND c.creation_date >= b.from_ts
    AND c.creation_date <  b.to_ts
),

/* -------------------------------------------------------------------------- */
/* comments the users left on answers – hop through answer to the question    */
c_on_a AS (
  SELECT
    c.user_id AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments`       AS c
  JOIN `bigquery-public-data.stackoverflow.posts_answers`  AS a
    ON a.id = c.post_id
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
    ON q.id = a.parent_id
  CROSS JOIN b
  WHERE c.user_id BETWEEN b.min_uid AND b.max_uid
    AND c.creation_date >= b.from_ts
    AND c.creation_date <  b.to_ts
)

/* -------------------------------------------------------------------------- */
SELECT
  user_id,
  tags                       -- pipe-separated list of tags on the associated question
FROM (
  SELECT * FROM q_contrib
  UNION ALL
  SELECT * FROM a_contrib
  UNION ALL
  SELECT * FROM c_on_q
  UNION ALL
  SELECT * FROM c_on_a
)
ORDER BY user_id;
-- Contributions (questions, answers, comments) July 1 – Dec 31 2019  
-- for users 16 712 208 – 18 712 208, paired with the tags of the
-- question each contribution relates to
WITH limits AS (
  SELECT
    TIMESTAMP('2019-07-01 00:00:00 UTC') AS d_from,
    TIMESTAMP('2020-01-01 00:00:00 UTC') AS d_to,
    16712208                                    AS u_from,
    18712208                                    AS u_to
)

SELECT user_id, tags
FROM (
  ------------------------------------------------------------------
  -- 1. questions these users asked
  ------------------------------------------------------------------
  SELECT
      q.owner_user_id          AS user_id,
      q.tags
  FROM  `bigquery-public-data.stackoverflow.posts_questions` q
  CROSS JOIN limits l
  WHERE q.creation_date BETWEEN l.d_from AND l.d_to
    AND q.owner_user_id BETWEEN l.u_from AND l.u_to

  UNION ALL
  ------------------------------------------------------------------
  -- 2. answers these users posted (look up parent question for tags)
  ------------------------------------------------------------------
  SELECT
      a.owner_user_id          AS user_id,
      q.tags
  FROM  `bigquery-public-data.stackoverflow.posts_answers`   a
  JOIN  `bigquery-public-data.stackoverflow.posts_questions` q
        ON a.parent_id = q.id
  CROSS JOIN limits l
  WHERE a.creation_date BETWEEN l.d_from AND l.d_to
    AND a.owner_user_id BETWEEN l.u_from AND l.u_to

  UNION ALL
  ------------------------------------------------------------------
  -- 3. comments they left directly on questions
  ------------------------------------------------------------------
  SELECT
      c.user_id,
      q.tags
  FROM  `bigquery-public-data.stackoverflow.comments`        c
  JOIN  `bigquery-public-data.stackoverflow.posts_questions` q
        ON c.post_id = q.id
  CROSS JOIN limits l
  WHERE c.creation_date BETWEEN l.d_from AND l.d_to
    AND c.user_id BETWEEN l.u_from AND l.u_to

  UNION ALL
  ------------------------------------------------------------------
  -- 4. comments they left on answers (via the answer’s parent question)
  ------------------------------------------------------------------
  SELECT
      c.user_id,
      q.tags
  FROM  `bigquery-public-data.stackoverflow.comments`        c
  JOIN  `bigquery-public-data.stackoverflow.posts_answers`   a
        ON c.post_id = a.id
  JOIN  `bigquery-public-data.stackoverflow.posts_questions` q
        ON a.parent_id = q.id
  CROSS JOIN limits l
  WHERE c.creation_date BETWEEN l.d_from AND l.d_to
    AND c.user_id BETWEEN l.u_from AND l.u_to
);
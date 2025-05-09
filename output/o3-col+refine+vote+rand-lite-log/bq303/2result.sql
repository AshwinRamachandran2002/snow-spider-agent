--  Contributing activity (questions, answers, comments) July-Dec 2019
--  by users whose ids are between 16 712 208 and 18 712 208.
--  For every contribution return the user id and the tags of the
--  question that contribution belongs to (or is itself).

WITH all_contributions AS (

  -- 1. Questions these users asked
  SELECT
      q.owner_user_id        AS user_id,
      q.tags                 AS question_tags
  FROM  `bigquery-public-data.stackoverflow.posts_questions`  q
  WHERE q.creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND q.owner_user_id BETWEEN 16712208 AND 18712208


  UNION ALL

  -- 2. Answers they posted (tags come from the parent question)
  SELECT
      a.owner_user_id        AS user_id,
      pq.tags                AS question_tags
  FROM  `bigquery-public-data.stackoverflow.posts_answers`    a
  JOIN  `bigquery-public-data.stackoverflow.posts_questions`  pq
        ON pq.id = a.parent_id
  WHERE a.creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND a.owner_user_id BETWEEN 16712208 AND 18712208


  UNION ALL

  -- 3. Comments written directly on questions
  SELECT
      c.user_id              AS user_id,
      pq.tags                AS question_tags
  FROM  `bigquery-public-data.stackoverflow.comments`         c
  JOIN  `bigquery-public-data.stackoverflow.posts_questions`  pq
        ON pq.id = c.post_id
  WHERE c.creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND c.user_id BETWEEN 16712208 AND 18712208


  UNION ALL

  -- 4. Comments written on answers (need the answer’s parent question)
  SELECT
      c.user_id              AS user_id,
      pq.tags                AS question_tags
  FROM  `bigquery-public-data.stackoverflow.comments`         c
  JOIN  `bigquery-public-data.stackoverflow.posts_answers`    pa
        ON pa.id = c.post_id
  JOIN  `bigquery-public-data.stackoverflow.posts_questions`  pq
        ON pq.id = pa.parent_id
  WHERE c.creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND c.user_id BETWEEN 16712208 AND 18712208
)

SELECT
  user_id,
  question_tags
FROM all_contributions;
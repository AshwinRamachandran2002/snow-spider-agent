-- Contributions (questions, answers, comments) made between
-- 2019‑07‑01 and 2019‑12‑31 by users whose IDs are in
-- [16 712 208 … 18 712 208], paired with the tags of the
-- corresponding parent question
WITH
-- questions authored in period
question_contribs AS (
  SELECT
    q.owner_user_id AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE q.creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND q.owner_user_id BETWEEN 16712208 AND 18712208
),

-- answers authored in period
answer_contribs AS (
  SELECT
    a.owner_user_id AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.posts_answers` AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
        ON q.id = a.parent_id               -- parent question
  WHERE a.creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND a.owner_user_id BETWEEN 16712208 AND 18712208
),

-- comments made directly on questions
comments_on_questions AS (
  SELECT
    c.user_id AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments` AS c
  JOIN `bigquery-public-data.stackoverflow.posts_questions` AS q
        ON q.id = c.post_id                 -- comment on question
  WHERE c.creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND c.user_id BETWEEN 16712208 AND 18712208
),

-- comments made on answers (need two‑step join to reach question)
comments_on_answers AS (
  SELECT
    c.user_id AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments`         AS c
  JOIN `bigquery-public-data.stackoverflow.posts_answers`    AS a
        ON a.id = c.post_id                  -- comment on answer
  JOIN `bigquery-public-data.stackoverflow.posts_questions`  AS q
        ON q.id = a.parent_id               -- parent question
  WHERE c.creation_date BETWEEN '2019-07-01' AND '2019-12-31'
    AND c.user_id BETWEEN 16712208 AND 18712208
)

-- combine all contribution types
SELECT user_id, tags
FROM (
  SELECT * FROM question_contribs
  UNION ALL
  SELECT * FROM answer_contribs
  UNION ALL
  SELECT * FROM comments_on_questions
  UNION ALL
  SELECT * FROM comments_on_answers
);
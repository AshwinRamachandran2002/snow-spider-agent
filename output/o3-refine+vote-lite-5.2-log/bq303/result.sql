/*  Users’ contributions (questions, answers, comments)   
    Jul‑01‑2019 – Dec‑31‑2019, users 16 712 208 – 18 712 208  */

WITH question_contrib AS (          -- questions authored
  SELECT
    owner_user_id          AS user_id,
    tags
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE owner_user_id BETWEEN 16712208 AND 18712208
    AND creation_date >= '2019-07-01' AND creation_date < '2020-01-01'
),

answer_contrib AS (            -- answers authored (join to parent question)
  SELECT
    a.owner_user_id         AS user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.posts_answers`     AS a
  JOIN `bigquery-public-data.stackoverflow.posts_questions`   AS q
        ON q.id = a.parent_id
  WHERE a.owner_user_id BETWEEN 16712208 AND 18712208
    AND a.creation_date >= '2019-07-01' AND a.creation_date < '2020-01-01'
),

comment_on_questions AS (      -- comments made directly on questions
  SELECT
    c.user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments`          AS c
  JOIN `bigquery-public-data.stackoverflow.posts_questions`   AS q
        ON q.id = c.post_id
  WHERE c.user_id BETWEEN 16712208 AND 18712208
    AND c.creation_date >= '2019-07-01' AND c.creation_date < '2020-01-01'
),

comment_on_answers AS (        -- comments made on answers → parent question
  SELECT
    c.user_id,
    q.tags
  FROM `bigquery-public-data.stackoverflow.comments`          AS c
  JOIN `bigquery-public-data.stackoverflow.posts_answers`     AS a
        ON a.id = c.post_id
  JOIN `bigquery-public-data.stackoverflow.posts_questions`   AS q
        ON q.id = a.parent_id
  WHERE c.user_id BETWEEN 16712208 AND 18712208
    AND c.creation_date >= '2019-07-01' AND c.creation_date < '2020-01-01'
)

-- combine every contribution
SELECT user_id, tags FROM question_contrib
UNION ALL
SELECT user_id, tags FROM answer_contrib
UNION ALL
SELECT user_id, tags FROM comment_on_questions
UNION ALL
SELECT user_id, tags FROM comment_on_answers;
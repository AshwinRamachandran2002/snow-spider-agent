-- Task: List the first 100 Python 2 specific questions on Stack Overflow, excluding any discussions that involve Python 3.
SELECT
  q.id AS question_id,
  q.title,
  q.body AS question_body,
  q.tags
FROM
  `bigquery-public-data.stackoverflow.posts_questions` q
WHERE
  (
    LOWER(q.tags) LIKE '%python-2%'
    OR LOWER(q.tags) LIKE '%python-2.x%'
    OR LOWER(q.title) LIKE '%python 2%'
    OR LOWER(q.body) LIKE '%python 2%'
    OR LOWER(q.title) LIKE '%python2%'
    OR LOWER(q.body) LIKE '%python2%'
  )
  AND NOT (
    LOWER(q.title) LIKE '%python 3%'
    OR LOWER(q.body) LIKE '%python 3%'
    OR LOWER(q.title) LIKE '%python3%'
    OR LOWER(q.body) LIKE '%python3%'
  )
LIMIT 100
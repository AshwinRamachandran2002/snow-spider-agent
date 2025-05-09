SELECT
  MAX(answer_count) AS highest_answer_count
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  tags LIKE '%python-2%'          -- Python 2–specific questions
  AND tags NOT LIKE '%python-3%'  -- exclude any mention of Python 3
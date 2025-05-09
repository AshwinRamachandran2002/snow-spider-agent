SELECT
  MAX(answer_count) AS max_answer_count
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE tags LIKE '%python-2%'         -- question has a Python-2 tag
  AND tags NOT LIKE '%python-3%'     -- …but no Python-3 tag
;
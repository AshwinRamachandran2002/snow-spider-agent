SELECT MAX(answer_count) AS Highest_number_of_answers
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE
(
  -- Include questions about Python 2
  (
    LOWER(title) LIKE '%python 2%' OR LOWER(body) LIKE '%python 2%' OR
    LOWER(title) LIKE '%python2%' OR LOWER(body) LIKE '%python2%' OR
    tags LIKE '%<python-2.x>%'
  )
)
AND NOT
(
  -- Exclude questions involving Python 3
  LOWER(title) LIKE '%python 3%' OR LOWER(body) LIKE '%python 3%' OR
  LOWER(title) LIKE '%python3%' OR LOWER(body) LIKE '%python3%' OR
  tags LIKE '%<python-3.x>%'
);
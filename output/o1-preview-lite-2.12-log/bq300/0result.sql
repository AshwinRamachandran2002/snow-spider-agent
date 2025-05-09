SELECT MAX(answer_count) AS Highest_number_of_answers
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE (
    LOWER(title) LIKE '%python 2%' 
    OR LOWER(body) LIKE '%python 2%' 
    OR tags LIKE '%<python-2.x>%'
  )
  AND LOWER(title) NOT LIKE '%python 3%'
  AND LOWER(body) NOT LIKE '%python 3%'
  AND tags NOT LIKE '%<python-3.x>%';
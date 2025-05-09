SELECT 
  MAX(answer_count) AS highest_python2_answer_total
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE tags LIKE '%python-2%'           -- question must reference Python 2
  AND tags NOT LIKE '%python-3%'       -- exclude any question that also references Python 3
  AND answer_count IS NOT NULL;
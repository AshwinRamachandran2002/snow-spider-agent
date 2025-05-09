SELECT
  MAX(answer_count) AS highest_answer_count
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE (
        COALESCE(tags,'') LIKE '%python-2%' OR
        COALESCE(tags,'') LIKE '%python2%'  OR
        LOWER(COALESCE(title,'')) LIKE '%python 2%' OR
        LOWER(COALESCE(body ,''))  LIKE '%python 2%'
      )
  AND COALESCE(tags,'') NOT LIKE '%python-3%'
  AND LOWER(COALESCE(title,'')) NOT LIKE '%python 3%'
  AND LOWER(COALESCE(body ,''))  NOT LIKE '%python 3%'
  AND LOWER(COALESCE(title,'')) NOT LIKE '%python3%'
  AND LOWER(COALESCE(body ,''))  NOT LIKE '%python3%';
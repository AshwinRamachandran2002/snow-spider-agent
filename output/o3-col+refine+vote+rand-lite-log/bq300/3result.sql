-- Highest number of answers ever received by a Python-2-only question 
-- (i.e. question tags mention Python 2 but do NOT mention Python 3)
SELECT
  MAX(answer_count) AS highest_answers_for_python2_only_question
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  (tags LIKE '%python-2.%' OR tags LIKE '%python2%')   -- keep Python-2 questions
  AND tags NOT LIKE '%python-3%'                       -- exclude any Python-3 mention
  AND tags NOT LIKE '%python3%';
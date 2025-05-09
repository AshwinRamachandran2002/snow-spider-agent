SELECT
  MAX(`answer_count`) AS max_answers_python2_only
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE (
        LOWER(`tags`) LIKE '%python-2.%'   -- any tag like python-2.7, python-2.x, etc.
        OR LOWER(`tags`) LIKE '%python2%'  -- covers python2, gae-python27, etc.
      )
  AND NOT LOWER(`tags`) LIKE '%python-3%'  -- ensure no Python-3 tag is present
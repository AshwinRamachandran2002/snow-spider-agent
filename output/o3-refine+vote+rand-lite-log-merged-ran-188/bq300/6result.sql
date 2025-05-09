SELECT
  MAX(answer_count) AS highest_answer_count_python2_question
FROM
  `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  -- Question has at least one Python 2‑specific tag …
  REGEXP_CONTAINS(tags, r'(?:^|\|)python-2[^|]*(?:$|\|)')
  -- … and no Python 3 related tag
  AND NOT REGEXP_CONTAINS(tags, r'(?:^|\|)python-3[^|]*(?:$|\|)')
  AND answer_count IS NOT NULL;
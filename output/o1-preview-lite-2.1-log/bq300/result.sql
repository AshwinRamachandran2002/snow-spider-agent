SELECT MAX(answer_count) AS Highest_number_of_answers
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE
  (
    REGEXP_CONTAINS(LOWER(COALESCE(title, '')), r'\bpython\s*2\b') OR
    REGEXP_CONTAINS(LOWER(COALESCE(body, '')), r'\bpython\s*2\b') OR
    REGEXP_CONTAINS(LOWER(COALESCE(tags, '')), r'(?i)<python-2(?:\.[^>]+)?>')
  )
  AND NOT (
    REGEXP_CONTAINS(LOWER(COALESCE(title, '')), r'\bpython\s*3\b') OR
    REGEXP_CONTAINS(LOWER(COALESCE(body, '')), r'\bpython\s*3\b') OR
    REGEXP_CONTAINS(LOWER(COALESCE(tags, '')), r'(?i)<python-3(?:\.[^>]+)?>')
  );
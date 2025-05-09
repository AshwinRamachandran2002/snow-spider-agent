SELECT
  MAX(answer_count) AS max_answers
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE answer_count IS NOT NULL
      -- keep questions that are explicitly about Python 2
  AND REGEXP_CONTAINS(tags, r'(^|[|])python-2[^|]*([|]|$)')
      -- discard any question that also mentions Python 3
  AND NOT REGEXP_CONTAINS(tags, r'(^|[|])python-3[^|]*([|]|$)');
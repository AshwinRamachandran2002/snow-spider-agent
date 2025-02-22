-- Task: Retrieve the title of the most viewed StackOverflow question where the title contains "how" (case-insensitive) and is tagged with any tag that includes "android" (case-insensitive).
SELECT title
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE LOWER(title) LIKE '%how%'
  AND EXISTS (
    SELECT 1 FROM UNNEST(SPLIT(REGEXP_REPLACE(tags, '^<|>$', ''), '><')) AS tag
    WHERE LOWER(tag) LIKE '%android%'
  )
ORDER BY view_count DESC
LIMIT 1;
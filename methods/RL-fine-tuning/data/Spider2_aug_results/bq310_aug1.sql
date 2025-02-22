-- Task: What is the title of the most viewed question on StackOverflow that contains 'how' in the title?
SELECT title
FROM `bigquery-public-data.stackoverflow.posts_questions`
WHERE LOWER(title) LIKE '%how%'
ORDER BY view_count DESC
LIMIT 1;
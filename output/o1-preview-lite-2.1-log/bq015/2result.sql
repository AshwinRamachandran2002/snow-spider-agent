SELECT tag, COUNT(*) AS Count
FROM (
  SELECT
    SPLIT(REPLACE(TRIM(Tags, '<>'), '><', ',')) AS tag_list
  FROM `bigquery-public-data.stackoverflow.posts_questions`
  WHERE Id IN (
    SELECT DISTINCT
      CAST(REGEXP_EXTRACT(url, r'stackoverflow\.com/questions/([0-9]+)') AS INT64)
    FROM `bigquery-public-data.hacker_news.full`
    WHERE url LIKE '%stackoverflow.com/questions/%'
      AND `timestamp` >= '2014-01-01'
  )
), UNNEST(tag_list) AS tag
GROUP BY tag
ORDER BY Count DESC
LIMIT 10;
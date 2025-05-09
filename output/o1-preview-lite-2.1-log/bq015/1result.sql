WITH hn_links AS (
  SELECT DISTINCT CAST(REGEXP_EXTRACT(url, r'questions/(\d+)/') AS INT64) AS question_id
  FROM `bigquery-public-data.hacker_news.full`
  WHERE `url` LIKE '%stackoverflow.com/questions/%'
    AND `timestamp` >= '2014-01-01'
    AND `type` = 'story'
    AND REGEXP_CONTAINS(url, r'questions/\d+/')
),
question_tags AS (
  SELECT
    q.id AS question_id,
    SPLIT(REGEXP_REPLACE(q.tags, r'^<|>$', ''), '><') AS tag_list
  FROM `bigquery-public-data.stackoverflow.posts_questions` AS q
  WHERE q.id IN (SELECT question_id FROM hn_links)
)
SELECT
  LOWER(tag) AS Tag,
  COUNT(*) AS Count
FROM question_tags, UNNEST(tag_list) AS tag
GROUP BY Tag
ORDER BY Count DESC
LIMIT 10;
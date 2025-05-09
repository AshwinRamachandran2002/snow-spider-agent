SELECT
  category,
  COUNT(*) AS total_articles,
  COUNTIF(LOWER(body) LIKE '%education%') AS articles_mentioning_education,
  ROUND(100 * COUNTIF(LOWER(body) LIKE '%education%') / COUNT(*), 4) AS education_mention_percentage
FROM `bigquery-public-data.bbc_news.fulltext`
GROUP BY category
ORDER BY category;
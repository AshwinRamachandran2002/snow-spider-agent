SELECT
  category,
  COUNT(*) AS total_articles,
  SUM(CASE WHEN LOWER(body) LIKE '%education%' OR LOWER(title) LIKE '%education%' THEN 1 ELSE 0 END) AS articles_mentioning_education,
  ROUND(100 * SUM(CASE WHEN LOWER(body) LIKE '%education%' OR LOWER(title) LIKE '%education%' THEN 1 ELSE 0 END) / COUNT(*), 4) AS education_mention_percentage
FROM `bigquery-public-data.bbc_news.fulltext`
GROUP BY category
ORDER BY education_mention_percentage DESC, category;
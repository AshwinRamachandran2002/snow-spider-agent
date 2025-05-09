SELECT
  `category`,
  COUNT(*) AS total_articles,
  SUM(CASE WHEN LOWER(`body`) LIKE '%education%' THEN 1 ELSE 0 END) AS education_articles,
  ROUND(
    100 * SUM(CASE WHEN LOWER(`body`) LIKE '%education%' THEN 1 ELSE 0 END) / COUNT(*),
    2
  ) AS education_percentage
FROM `bigquery-public-data.bbc_news.fulltext`
GROUP BY `category`
ORDER BY education_percentage DESC;
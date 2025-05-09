SELECT
  `category`,
  COUNT(*) AS total_articles,
  SUM(CASE WHEN REGEXP_CONTAINS(LOWER(`body`), r'\beducation\b') THEN 1 ELSE 0 END) AS education_articles,
  ROUND(
    100 * SAFE_DIVIDE(
      SUM(CASE WHEN REGEXP_CONTAINS(LOWER(`body`), r'\beducation\b') THEN 1 ELSE 0 END),
      COUNT(*)
    ), 
    4
  ) AS education_pct
FROM `bigquery-public-data.bbc_news.fulltext`
GROUP BY `category`
ORDER BY total_articles DESC;
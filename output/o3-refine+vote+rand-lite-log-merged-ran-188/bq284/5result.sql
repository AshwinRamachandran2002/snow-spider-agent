SELECT
  category,
  COUNT(*) AS total_articles,
  COUNTIF(LOWER(body)  LIKE '%education%' OR
          LOWER(title) LIKE '%education%') AS education_articles,
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(LOWER(body)  LIKE '%education%' OR
              LOWER(title) LIKE '%education%'),
      COUNT(*)
    ) * 100, 
    4
  ) AS education_percentage
FROM `bigquery-public-data.bbc_news.fulltext`
GROUP BY category
ORDER BY category;
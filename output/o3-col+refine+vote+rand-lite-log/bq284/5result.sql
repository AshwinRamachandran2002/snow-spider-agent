SELECT
  category,
  COUNT(*) AS total_articles,
  SUM(
    CASE
      WHEN REGEXP_CONTAINS(LOWER(CONCAT(title, ' ', body)), r'\beducation\b')
      THEN 1 ELSE 0
    END
  ) AS education_articles,
  ROUND(
    100.0 * SUM(
      CASE
        WHEN REGEXP_CONTAINS(LOWER(CONCAT(title, ' ', body)), r'\beducation\b')
        THEN 1 ELSE 0
      END
    ) / COUNT(*), 2
  ) AS pct_with_education
FROM `bigquery-public-data.bbc_news.fulltext`
GROUP BY category
ORDER BY pct_with_education DESC;
SELECT
  category,
  COUNT(*) AS total_articles,
  SUM(
    CASE
      WHEN REGEXP_CONTAINS(LOWER(body),  r'\beducation\b')
        OR REGEXP_CONTAINS(LOWER(title), r'\beducation\b')
      THEN 1 ELSE 0
    END
  ) AS education_articles,
  ROUND(
    SUM(
      CASE
        WHEN REGEXP_CONTAINS(LOWER(body),  r'\beducation\b')
          OR REGEXP_CONTAINS(LOWER(title), r'\beducation\b')
        THEN 1 ELSE 0
      END
    ) / COUNT(*) * 100,
    4
  ) AS education_percentage
FROM `bigquery-public-data.bbc_news.fulltext`
GROUP BY category
ORDER BY category;
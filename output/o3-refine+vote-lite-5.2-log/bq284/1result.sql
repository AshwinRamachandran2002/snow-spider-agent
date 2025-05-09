WITH stats AS (
  SELECT
    category,
    COUNT(*) AS total_articles,
    SUM(
      CASE
        WHEN REGEXP_CONTAINS(LOWER(body),  r'\beducation\b')
          OR REGEXP_CONTAINS(LOWER(title), r'\beducation\b')
        THEN 1
        ELSE 0
      END
    ) AS education_articles
  FROM `bigquery-public-data.bbc_news.fulltext`
  GROUP BY category
)
SELECT
  category,
  total_articles,
  education_articles,
  ROUND(SAFE_DIVIDE(education_articles, total_articles) * 100, 4) AS pct_education
FROM stats
ORDER BY category;
SELECT
  category,
  COUNT(*) AS total_articles,
  SUM(
    CASE
      WHEN REGEXP_CONTAINS(
             LOWER(CONCAT(COALESCE(title,''), ' ', COALESCE(body,''))),
             r'\beducation\b'
           )
      THEN 1
      ELSE 0
    END
  ) AS education_mentions,
  ROUND(
    SUM(
      CASE
        WHEN REGEXP_CONTAINS(
               LOWER(CONCAT(COALESCE(title,''), ' ', COALESCE(body,''))),
               r'\beducation\b'
             )
        THEN 1
        ELSE 0
      END
    ) * 100.0 / COUNT(*),
    4
  ) AS education_percentage
FROM
  `bigquery-public-data.bbc_news.fulltext`
GROUP BY
  category
ORDER BY
  total_articles DESC,
  category;
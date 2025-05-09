SELECT
  category,
  COUNT(*) AS total_articles,
  SUM(
    CASE
      WHEN REGEXP_CONTAINS(
             LOWER(CONCAT(IFNULL(title, ''), ' ', IFNULL(body, ''))),
             r'\beducation\b'
           )
      THEN 1
      ELSE 0
    END
  ) AS education_articles,
  ROUND(
    100 * SUM(
            CASE
              WHEN REGEXP_CONTAINS(
                     LOWER(CONCAT(IFNULL(title, ''), ' ', IFNULL(body, ''))),
                     r'\beducation\b'
                   )
              THEN 1
              ELSE 0
            END
          ) / COUNT(*),
    4
  ) AS education_percentage
FROM `bigquery-public-data.bbc_news.fulltext`
GROUP BY category
ORDER BY category;
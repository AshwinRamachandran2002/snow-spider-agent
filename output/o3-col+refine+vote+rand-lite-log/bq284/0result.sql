WITH totals AS (
  SELECT
    `category`,
    COUNT(*) AS total_articles
  FROM `bigquery-public-data.bbc_news.fulltext`
  GROUP BY `category`
),
education AS (
  SELECT
    `category`,
    COUNT(*) AS education_articles
  FROM `bigquery-public-data.bbc_news.fulltext`
  WHERE LOWER(`body`)  LIKE '%education%'
     OR LOWER(`title`) LIKE '%education%'
  GROUP BY `category`
)
SELECT
  t.category,
  t.total_articles,
  COALESCE(e.education_articles, 0)                         AS education_articles,
  ROUND(100 * COALESCE(e.education_articles, 0) 
            / t.total_articles, 2)                          AS pct_education
FROM totals AS t
LEFT JOIN education AS e
USING (`category`)
ORDER BY t.category;
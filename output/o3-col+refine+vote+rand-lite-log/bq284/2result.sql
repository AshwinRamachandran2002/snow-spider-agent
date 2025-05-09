WITH total AS (
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
  WHERE LOWER(CONCAT(IFNULL(`title`, ''), ' ', IFNULL(`body`, ''))) LIKE '%education%'
  GROUP BY `category`
)
SELECT
  t.`category`,
  t.total_articles,
  COALESCE(e.education_articles, 0) AS education_articles,
  ROUND(
    SAFE_DIVIDE(COALESCE(e.education_articles, 0), t.total_articles) * 100,
    2
  ) AS education_percentage
FROM total AS t
LEFT JOIN education AS e
USING (`category`)
ORDER BY education_percentage DESC;
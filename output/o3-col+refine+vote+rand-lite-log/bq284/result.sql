SELECT
  tot.category,
  tot.total_articles,
  IFNULL(edu.education_mentions, 0) AS education_mentions,
  ROUND(100 * IFNULL(edu.education_mentions, 0) / tot.total_articles, 2) AS pct_with_education
FROM (
  SELECT
    category,
    COUNT(*) AS total_articles
  FROM
    `bigquery-public-data.bbc_news.fulltext`
  GROUP BY
    category
) AS tot
LEFT JOIN (
  SELECT
    category,
    COUNT(*) AS education_mentions
  FROM
    `bigquery-public-data.bbc_news.fulltext`
  WHERE
    LOWER(body)  LIKE '%education%'
    OR LOWER(title) LIKE '%education%'
  GROUP BY
    category
) AS edu
USING (category)
ORDER BY
  pct_with_education DESC;
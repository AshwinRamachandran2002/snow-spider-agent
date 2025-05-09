SELECT
  `category`,
  COUNT(DISTINCT `filename`) AS total_articles,
  COUNT(DISTINCT IF(
        LOWER(`body`)  LIKE '%education%' OR
        LOWER(`title`) LIKE '%education%',
        `filename`, NULL)
  ) AS articles_mentioning_education,
  ROUND(
    SAFE_DIVIDE(
      COUNT(DISTINCT IF(
            LOWER(`body`)  LIKE '%education%' OR
            LOWER(`title`) LIKE '%education%',
            `filename`, NULL)
      ),
      COUNT(DISTINCT `filename`)
    ) * 100,
    4
  ) AS education_mention_percentage
FROM `bigquery-public-data.bbc_news.fulltext`
GROUP BY `category`
ORDER BY `category`;
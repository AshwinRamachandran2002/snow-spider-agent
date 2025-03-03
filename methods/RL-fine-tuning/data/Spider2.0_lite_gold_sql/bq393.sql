SELECT
  `by` AS ID,
  EXTRACT(MONTH FROM MAX(timestamp)) AS Month_number
FROM
  `bigquery-public-data.hacker_news.full`
WHERE
  `by` IS NOT NULL
  AND timestamp <= '2024-09-10'
GROUP BY
  `by`
HAVING
  MAX(timestamp) < '2024-09-10'
ORDER BY
  Month_number DESC
LIMIT
  1
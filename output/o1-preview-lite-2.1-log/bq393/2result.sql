SELECT `by` AS ID, EXTRACT(MONTH FROM MAX(`timestamp`)) AS Month_number
FROM `bigquery-public-data.hacker_news.full`
WHERE `timestamp` <= '2024-09-10'
  AND `by` IS NOT NULL AND `by` != ''
GROUP BY `by`
ORDER BY Month_number DESC
LIMIT 1
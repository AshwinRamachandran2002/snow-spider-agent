-- Task: Which visitor IDs made their first transaction on a mobile device?
SELECT t.fullvisitorid
FROM (
  SELECT fullvisitorid, MIN(date) AS date_transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS ga, 
  UNNEST(ga.hits) AS hits 
  WHERE hits.transaction.transactionId IS NOT NULL 
  GROUP BY fullvisitorid
) t
JOIN `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS ga
  ON t.fullvisitorid = ga.fullvisitorid AND t.date_transactions = ga.date
WHERE ga.device.deviceCategory = 'mobile'
LIMIT 100;
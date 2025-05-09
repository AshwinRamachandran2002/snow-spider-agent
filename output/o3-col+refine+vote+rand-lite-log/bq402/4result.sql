WITH visitor_transactions AS (
  SELECT
    fullVisitorId,
    SUM(IFNULL(totals.transactions, 0)) AS total_transactions
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullVisitorId
)
SELECT
  COUNT(*)                                                        AS total_visitors,
  COUNTIF(total_transactions > 0)                                 AS total_purchasers,
  SAFE_DIVIDE(COUNTIF(total_transactions > 0), COUNT(*))          AS conversion_rate,
  AVG(IF(total_transactions > 0, total_transactions, NULL))       AS avg_transactions_per_purchaser
FROM visitor_transactions;
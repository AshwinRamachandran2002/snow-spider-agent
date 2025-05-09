WITH agg AS (
  SELECT
    fullVisitorId,
    SUM(IFNULL(transactions, 0)) AS total_transactions
  FROM `data-to-insights.ecommerce.all_sessions`
  WHERE fullVisitorId IS NOT NULL
  GROUP BY fullVisitorId
)
SELECT
  100.0 * COUNTIF(total_transactions > 0) / COUNT(*) AS conversion_rate_from_unique_visitors_to_purchasers,
  SUM(IF(total_transactions > 0, total_transactions, 0)) / COUNTIF(total_transactions > 0) AS average_transactions_per_purchaser
FROM agg;
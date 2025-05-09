WITH visitor_transactions AS (
  SELECT
    fullVisitorId,
    SUM(IFNULL(transactions, 0)) AS total_transactions
  FROM
    `data-to-insights.ecommerce.all_sessions`
  GROUP BY
    fullVisitorId
),
stats AS (
  SELECT
    COUNT(*) AS total_visitors,
    COUNTIF(total_transactions > 0) AS purchasers,
    AVG(CASE WHEN total_transactions > 0 THEN total_transactions END) AS average_transactions_per_purchaser
  FROM
    visitor_transactions
)
SELECT
  ROUND((purchasers / total_visitors) * 100, 4) AS conversion_rate_from_unique_visitors_to_purchasers,
  ROUND(average_transactions_per_purchaser, 4) AS average_transactions_per_purchaser
FROM
  stats;
SELECT
  COUNTIF(total_transactions > 0) * 100.0 / COUNT(*) AS conversion_rate_from_unique_visitors_to_purchasers,
  SUM(total_transactions) / COUNTIF(total_transactions > 0) AS average_transactions_per_purchaser
FROM (
  SELECT
    `fullVisitorId`,
    SUM(IFNULL(`transactions`, 0)) AS total_transactions
  FROM
    `data-to-insights.ecommerce.all_sessions`
  GROUP BY
    `fullVisitorId`
)
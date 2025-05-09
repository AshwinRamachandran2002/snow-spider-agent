WITH visitor_transactions AS (
  SELECT
    fullVisitorId,
    -- Sum the number of transactions made by each visitor across all their sessions
    SUM(CAST(totals.transactions AS INT64)) AS total_transactions
  FROM
    `data-to-insights.ecommerce.web_analytics`
  GROUP BY
    fullVisitorId
)

SELECT
  COUNT(*) AS unique_visitors,
  COUNTIF(total_transactions > 0) AS unique_purchasers,
  SAFE_DIVIDE(COUNTIF(total_transactions > 0), COUNT(*)) AS conversion_rate,
  AVG(IF(total_transactions > 0, total_transactions, NULL)) AS avg_transactions_per_purchaser
FROM
  visitor_transactions;
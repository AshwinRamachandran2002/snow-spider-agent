WITH visitor_txns AS (
  -- 1. Total transactions per unique visitor
  SELECT
    `fullVisitorId`,
    SUM(COALESCE(totals.transactions, 0)) AS total_transactions
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY `fullVisitorId`
),
summary AS (
  -- 2. Count visitors & purchasers and average transactions per purchaser
  SELECT
    COUNT(*)                                          AS total_visitors,
    COUNTIF(total_transactions > 0)                   AS purchasers,
    AVG(CASE WHEN total_transactions > 0
             THEN total_transactions END)             AS avg_txns_per_purchaser
  FROM visitor_txns
)
-- 3. Compute conversion rate
SELECT
  SAFE_DIVIDE(purchasers, total_visitors) AS conversion_rate,
  avg_txns_per_purchaser                  AS avg_transactions_per_purchaser
FROM summary;
WITH visitors AS (
  SELECT DISTINCT fullVisitorId
  FROM `data-to-insights.ecommerce.web_analytics`
),
purchasers AS (
  SELECT
    fullVisitorId,
    SUM(totals.transactions) AS total_transactions
  FROM `data-to-insights.ecommerce.web_analytics`
  WHERE totals.transactions IS NOT NULL
  GROUP BY fullVisitorId
)
SELECT
  FORMAT('%.4f', SAFE_DIVIDE(COUNT(*), (SELECT COUNT(*) FROM visitors))) AS conversion_rate,
  FORMAT('%.4f', AVG(total_transactions)) AS avg_transactions_per_purchaser
FROM purchasers;
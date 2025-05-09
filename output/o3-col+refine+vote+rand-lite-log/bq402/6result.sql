WITH purchasers AS (
  -- every visitor who made at least one transaction
  SELECT
    `fullVisitorId`,
    SUM(`totals`.transactions) AS total_transactions
  FROM `data-to-insights.ecommerce.web_analytics`
  WHERE `totals`.transactions IS NOT NULL
  GROUP BY `fullVisitorId`
),
visitor_totals AS (
  -- count of all distinct visitors
  SELECT COUNT(DISTINCT `fullVisitorId`) AS total_visitors
  FROM `data-to-insights.ecommerce.web_analytics`
)

SELECT
  ROUND( COUNT(*) / (SELECT total_visitors FROM visitor_totals), 4) AS conversion_rate,
  ROUND( AVG(total_transactions), 4)                               AS avg_transactions_per_purchaser
FROM purchasers;
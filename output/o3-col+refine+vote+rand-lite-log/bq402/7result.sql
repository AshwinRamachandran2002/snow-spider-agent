-- Conversion rate and average transactions per purchaser
WITH
  -- total number of unique visitors
  visitors AS (
    SELECT COUNT(DISTINCT `fullVisitorId`) AS total_visitors
    FROM `data-to-insights.ecommerce.web_analytics`
  ),
  -- visitors who completed at least one transaction
  purchasers AS (
    SELECT
      `fullVisitorId`,
      SUM(`totals`.transactions) AS total_transactions
    FROM `data-to-insights.ecommerce.web_analytics`
    WHERE `totals`.transactions IS NOT NULL
      AND `totals`.transactions > 0
    GROUP BY `fullVisitorId`
  )
SELECT
  ROUND(COUNT(*) / CAST((SELECT total_visitors FROM visitors) AS FLOAT64), 4) AS conversion_rate,
  ROUND(AVG(total_transactions), 4)                                           AS avg_transactions_per_purchaser
FROM purchasers;
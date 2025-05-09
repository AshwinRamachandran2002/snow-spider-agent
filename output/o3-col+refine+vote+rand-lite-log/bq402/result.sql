-- Conversion rate & avg transactions (web_analytics table only)
WITH
-- 1) total visitors and purchasers
visitor_stats AS (
  SELECT
    COUNT(DISTINCT `fullVisitorId`)                                                     AS total_visitors,
    COUNT(DISTINCT IF(`totals`.transactions IS NOT NULL, `fullVisitorId`, NULL))        AS total_purchasers
  FROM `data-to-insights.ecommerce.web_analytics`
),
-- 2) transactions aggregated at visitor level (purchasers only)
purchaser_tx AS (
  SELECT
    `fullVisitorId`,
    SUM(IFNULL(`totals`.transactions, 0)) AS transactions_per_visitor
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY `fullVisitorId`
  HAVING transactions_per_visitor > 0               -- keep only purchasers
)
SELECT
  SAFE_DIVIDE(vs.total_purchasers, vs.total_visitors)            AS conversion_rate,
  (SELECT AVG(transactions_per_visitor) FROM purchaser_tx)       AS avg_transactions_per_purchaser
FROM visitor_stats AS vs;
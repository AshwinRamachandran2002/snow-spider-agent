-- Conversion rate and average transactions per purchaser
WITH visitor_activity AS (
  -- Pull each row’s visitor id and (possible) transaction count
  SELECT
    fullVisitorId,
    IFNULL(totals.transactions, 0) AS transactions   -- totals is a STRUCT
  FROM
    `data-to-insights.ecommerce.web_analytics`
  WHERE
    fullVisitorId IS NOT NULL                        -- exclude rows without a visitor id
),
per_visitor_totals AS (
  -- Aggregate to one row per visitor
  SELECT
    fullVisitorId,
    SUM(transactions) AS total_transactions          -- add up all sessions for the visitor
  FROM
    visitor_activity
  GROUP BY
    fullVisitorId
)
SELECT
  COUNT(*)                                                AS unique_visitors,
  COUNTIF(total_transactions > 0)                         AS unique_purchasers,
  SAFE_DIVIDE(COUNTIF(total_transactions > 0),            -- purchasers ÷ visitors
              COUNT(*))                                   AS conversion_rate,
  ROUND(                                                   -- average number of transactions per purchaser
    SAFE_DIVIDE(
      SUM(CASE WHEN total_transactions > 0 THEN total_transactions END),
      COUNTIF(total_transactions > 0)
    ), 4)                                                 AS avg_transactions_per_purchaser
FROM
  per_visitor_totals;
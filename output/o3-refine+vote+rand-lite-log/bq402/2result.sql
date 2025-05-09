WITH base AS (
  -- 1 row per hit/session kept as–is (only the fields we need)
  SELECT
    fullVisitorId,
    CAST(totals.transactions AS INT64) AS transactions           -- may be NULL
  FROM `data-to-insights.ecommerce.web_analytics`
),
-- distinct visitors
visitors AS (
  SELECT DISTINCT
         fullVisitorId
  FROM base
),
-- visitors who purchased at least once
purchasers AS (
  SELECT
    fullVisitorId,
    SUM(transactions) AS total_transactions                      -- sum of all their transactions
  FROM base
  WHERE transactions IS NOT NULL AND transactions > 0
  GROUP BY fullVisitorId
)

SELECT
  -- totals
  (SELECT COUNT(*) FROM visitors)               AS total_unique_visitors,
  (SELECT COUNT(*) FROM purchasers)             AS total_unique_purchasers,

  -- conversion rate  = purchasers / visitors
  ROUND(
        (SELECT COUNT(*) FROM purchasers)
        /
        CAST((SELECT COUNT(*) FROM visitors) AS FLOAT64)
       ,4)                                      AS conversion_rate,

  -- average transactions per purchaser
  ROUND(
        (SELECT AVG(total_transactions) FROM purchasers)
       ,4)                                      AS avg_transactions_per_purchaser;
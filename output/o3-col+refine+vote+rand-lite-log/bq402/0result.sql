/* Conversion-rate and average transactions per purchaser
   using only data-to-insights.ecommerce.web_analytics            */
WITH base AS (
  SELECT
    fullVisitorId,
    totals.transactions AS tx
  FROM `data-to-insights.ecommerce.web_analytics`
  WHERE fullVisitorId IS NOT NULL
)
SELECT
  COUNT(DISTINCT IF(tx IS NOT NULL AND tx > 0, fullVisitorId, NULL))     AS unique_purchasers,
  COUNT(DISTINCT fullVisitorId)                                          AS unique_visitors,
  SAFE_DIVIDE(
      COUNT(DISTINCT IF(tx IS NOT NULL AND tx > 0, fullVisitorId, NULL)),
      COUNT(DISTINCT fullVisitorId)
  )                                                                      AS conversion_rate,
  AVG(CASE WHEN tx IS NOT NULL AND tx > 0 THEN tx END)                   AS avg_transactions_per_purchaser
FROM base;
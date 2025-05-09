-- Conversion rate & average transactions per purchaser  
--   • Conversion rate  = unique purchasers / unique visitors  
--   • Avg transactions = total transactions   / unique purchasers  

WITH web AS (
  SELECT
    fullVisitorId,
    totals.transactions AS transactions
  FROM `data-to-insights.ecommerce.web_analytics`
  WHERE fullVisitorId IS NOT NULL
),
agg AS (
  SELECT
    COUNT(DISTINCT fullVisitorId)                                            AS unique_visitors,
    COUNT(DISTINCT IF(transactions IS NOT NULL AND transactions > 0,
                      fullVisitorId,
                      NULL))                                                 AS unique_purchasers,
    SUM(IF(transactions IS NOT NULL, transactions, 0))                       AS total_transactions
  FROM web
)

SELECT
  unique_visitors,
  unique_purchasers,
  ROUND(SAFE_DIVIDE(unique_purchasers , unique_visitors)      , 4) AS conversion_rate,
  ROUND(SAFE_DIVIDE(total_transactions, unique_purchasers)    , 4) AS avg_transactions_per_purchaser
FROM agg;
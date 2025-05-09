-- Conversion rate & average transactions per purchaser
WITH visitor_summary AS (
  SELECT
    fullVisitorId,
    SUM(IFNULL(totals.transactions,0)) AS total_transactions
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullVisitorId
),
metrics AS (
  SELECT
    COUNT(*)                                       AS unique_visitors,
    COUNTIF(total_transactions > 0)                AS purchasers,
    SAFE_DIVIDE(COUNTIF(total_transactions > 0), 
                COUNT(*))                          AS conversion_rate,
    AVG(CASE WHEN total_transactions > 0 
             THEN total_transactions END)          AS avg_transactions_per_purchaser
  FROM visitor_summary
)
SELECT *
FROM metrics;
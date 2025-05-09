WITH visitor_level AS (
  SELECT
    `fullVisitorId`                    AS visitor_id,
    SUM(IFNULL(`totals`.transactions, 0)) AS visitor_transactions
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY visitor_id
)

SELECT
  COUNT(*)                                                   AS unique_visitors,
  COUNTIF(visitor_transactions > 0)                          AS unique_purchasers,
  SAFE_DIVIDE(COUNTIF(visitor_transactions > 0), COUNT(*))   AS conversion_rate,
  SUM(visitor_transactions)                                  AS total_transactions,
  AVG(CASE WHEN visitor_transactions > 0 
           THEN visitor_transactions END)                    AS avg_transactions_per_purchaser
FROM visitor_level;
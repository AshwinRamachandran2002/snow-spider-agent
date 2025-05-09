WITH per_visitor AS (
  SELECT
    fullVisitorId,
    SUM(COALESCE(totals.transactions, 0)) AS total_transactions
  FROM `data-to-insights.ecommerce.web_analytics`
  WHERE fullVisitorId IS NOT NULL
  GROUP BY fullVisitorId
)

SELECT
  COUNT(*)                                               AS unique_visitors,
  COUNTIF(total_transactions > 0)                        AS unique_purchasers,
  SAFE_DIVIDE(COUNTIF(total_transactions > 0), COUNT(*)) AS conversion_rate,
  AVG(CASE WHEN total_transactions > 0 
           THEN total_transactions END)                  AS avg_transactions_per_purchaser
FROM per_visitor;
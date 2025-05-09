WITH tx_per_visitor AS (
  SELECT
    fullVisitorId,
    SUM(CAST(IFNULL(totals.transactions, 0) AS INT64)) AS transactions
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullVisitorId
)
SELECT
  FORMAT('%.4f', SAFE_DIVIDE(COUNTIF(transactions > 0), COUNT(*))) AS conversion_rate,
  FORMAT('%.4f', AVG(NULLIF(transactions, 0)))                     AS avg_transactions_per_purchaser
FROM tx_per_visitor;
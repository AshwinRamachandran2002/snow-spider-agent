WITH tx_by_visitor AS (
  SELECT
    fullVisitorId,
    SUM(IFNULL(totals.transactions, 0)) AS transactions_per_visitor
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullVisitorId
)
SELECT
  ROUND(
    SAFE_DIVIDE(
      COUNTIF(transactions_per_visitor > 0),   -- unique purchasers
      COUNT(*)                                 -- total unique visitors
    ), 
    4
  ) AS conversion_rate,
  ROUND(
    AVG(
      IF(transactions_per_visitor > 0, transactions_per_visitor, NULL)
    ),
    4
  ) AS avg_transactions_per_purchaser
FROM tx_by_visitor;
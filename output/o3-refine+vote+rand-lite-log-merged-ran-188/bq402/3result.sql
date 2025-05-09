WITH per_visitor AS (
  -- Aggregate transactions at the visitor level
  SELECT
    fullVisitorId,
    SUM(IFNULL(totals.transactions, 0)) AS total_transactions
  FROM `data-to-insights.ecommerce.web_analytics`
  GROUP BY fullVisitorId
),
aggregates AS (
  -- Compute overall counts and sums needed for the metrics
  SELECT
    COUNT(*)                                                AS unique_visitors,                          -- all visitors
    COUNTIF(total_transactions > 0)                         AS unique_purchasers,                        -- visitors with ≥1 transaction
    SUM(CASE WHEN total_transactions > 0
             THEN total_transactions
             ELSE 0 END)                                    AS transactions_from_purchasers             -- total transactions made by purchasers
  FROM per_visitor
)
SELECT
  unique_visitors,
  unique_purchasers,
  SAFE_DIVIDE(unique_purchasers, unique_visitors)           AS conversion_rate,                          -- purchasers / visitors
  SAFE_DIVIDE(transactions_from_purchasers, unique_purchasers)
                                                           AS avg_transactions_per_purchaser            -- average transactions among purchasers
FROM aggregates;
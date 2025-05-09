WITH
  -- All distinct visitors
  visitors AS (
    SELECT DISTINCT fullVisitorId
    FROM `data-to-insights.ecommerce.web_analytics`
  ),

  -- Visitors who completed ≥1 transaction and how many they made
  purchaser_txn AS (
    SELECT
      fullVisitorId,
      SUM(totals.transactions) AS total_transactions
    FROM `data-to-insights.ecommerce.web_analytics`
    WHERE totals.transactions IS NOT NULL
    GROUP BY fullVisitorId
  )

-- Final metrics
SELECT
  (SELECT COUNT(*) FROM purchaser_txn)                                 AS unique_purchasers,
  (SELECT COUNT(*) FROM visitors)                                      AS total_unique_visitors,
  SAFE_DIVIDE((SELECT COUNT(*) FROM purchaser_txn),
              (SELECT COUNT(*) FROM visitors))                         AS conversion_rate,
  AVG(total_transactions)                                              AS avg_transactions_per_purchaser
FROM purchaser_txn;
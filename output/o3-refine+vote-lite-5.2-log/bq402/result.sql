WITH visitor_level AS (
  -- Bring every row down to one record per visitor
  SELECT
    fullVisitorId,
    SUM(IFNULL(totals.transactions,0)) AS total_transactions          -- sum of all their transactions
  FROM
    `data-to-insights.ecommerce.web_analytics`
  GROUP BY
    fullVisitorId
),
aggregated AS (
  SELECT
    COUNT(*)                                        AS unique_visitors,
    COUNTIF(total_transactions > 0)                 AS unique_purchasers,
    SUM(total_transactions)                         AS total_transactions_made
  FROM
    visitor_level
)
SELECT
  SAFE_DIVIDE(unique_purchasers, unique_visitors)      AS conversion_rate,
  SAFE_DIVIDE(total_transactions_made, unique_purchasers) AS avg_transactions_per_purchaser
FROM
  aggregated;
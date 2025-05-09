-- Conversion rate & average transactions per purchaser
WITH sessions AS (
  -- pull the visitor id and the number of transactions in each session
  SELECT
    fullVisitorId,
    totals.transactions AS transactions
  FROM
    `data-to-insights.ecommerce.web_analytics`
),
visitor_level AS (
  -- aggregate to visitor‑level total transactions
  SELECT
    fullVisitorId,
    SUM(IFNULL(transactions,0)) AS total_transactions
  FROM
    sessions
  GROUP BY
    fullVisitorId
)
SELECT
  COUNT(*)                                            AS unique_visitors,
  COUNTIF(total_transactions > 0)                    AS unique_purchasers,
  ROUND( SAFE_DIVIDE(COUNTIF(total_transactions > 0), COUNT(*)), 4) AS conversion_rate,
  ROUND( AVG(NULLIF(total_transactions,0)), 4)       AS avg_transactions_per_purchaser
FROM
  visitor_level;
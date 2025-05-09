-- Visitors whose very first transaction
--   • happened on a device flagged as “mobile”
--   • and occurred after their very first site visit
SELECT DISTINCT fv.fullVisitorId
FROM (
  -- First-ever visit for every visitor
  SELECT
    fullVisitorId,
    MIN(PARSE_DATE('%Y%m%d', date)) AS first_visit_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
)               AS fv
JOIN (
  -- First session that contains a transaction (any device)
  -- Keep only those whose device isMobile = TRUE
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date) AS first_txn_date
  FROM (
    SELECT
      fullVisitorId,
      date,
      device.isMobile                       AS is_mobile,
      ROW_NUMBER() OVER (
        PARTITION BY fullVisitorId
        ORDER BY PARSE_DATE('%Y%m%d', date)
      )                                     AS rn
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    WHERE totals.transactions >= 1           -- sessions with ≥1 transaction
  )
  WHERE rn = 1                               -- keep *first* transaction session
    AND is_mobile = TRUE                     -- must be on mobile device
)               AS ft
ON fv.fullVisitorId = ft.fullVisitorId
WHERE ft.first_txn_date > fv.first_visit_date -- txn occurs after first visit
ORDER BY fv.fullVisitorId;
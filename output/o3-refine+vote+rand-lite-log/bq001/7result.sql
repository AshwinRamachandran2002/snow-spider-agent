/*  Days between a visitor’s first February‑2017 visit
    and their first February‑2017 transaction,
    together with the device category used for that transaction        */

WITH feb_sessions AS (                       -- every Feb‑2017 session
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)                  AS session_date,
    visitStartTime,
    device.deviceCategory                       AS device_category,
    -- flag if the session contains at least one transaction hit
    EXISTS (
      SELECT 1
      FROM UNNEST(hits) h
      WHERE h.transaction.transactionId IS NOT NULL
    )                                           AS has_transaction
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201702*`
),

first_visit AS (                               -- first Feb visit
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM feb_sessions
  GROUP BY fullVisitorId
),

tx_sessions AS (                               -- sessions with a transaction
  SELECT
    fullVisitorId,
    session_date  AS tx_date,
    visitStartTime,
    device_category
  FROM feb_sessions
  WHERE has_transaction
),

first_tx AS (                                  -- earliest transaction session
  SELECT
    fullVisitorId,
    tx_date,
    device_category,
    ROW_NUMBER() OVER (PARTITION BY fullVisitorId
                       ORDER BY tx_date, visitStartTime) AS rn
  FROM tx_sessions
)

SELECT
  fv.fullVisitorId,
  DATE_DIFF(ft.tx_date, fv.first_visit_date, DAY)
      AS days_between_first_visit_and_first_tx,
  ft.device_category AS device_category_of_first_tx
FROM first_visit fv
JOIN first_tx    ft
  ON fv.fullVisitorId = ft.fullVisitorId
WHERE ft.rn = 1                                -- keep only earliest tx
ORDER BY days_between_first_visit_and_first_tx, fullVisitorId;
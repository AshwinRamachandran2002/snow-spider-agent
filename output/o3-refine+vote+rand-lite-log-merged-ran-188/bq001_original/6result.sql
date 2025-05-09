/*  Visitors that generated at least one transaction in February‑2017:
    – first day they visited in Feb (could be a non‑transactional session)
    – first day they transacted in Feb
    – days elapsed between the two
    – device category used for that first transaction
*/

WITH feb_sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)           AS session_date,
    totals.transactions                  AS transactions,
    device.deviceCategory                AS device_category
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE date BETWEEN '20170201' AND '20170228'            -- February 2017 only
),

-- first visit (any session) in February
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM feb_sessions
  GROUP BY fullVisitorId
),

-- first session that contains a transaction in February
first_tx AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_tx_date
  FROM feb_sessions
  WHERE transactions IS NOT NULL
        AND transactions > 0
  GROUP BY fullVisitorId
),

-- attach the device category used in the first transaction session
first_tx_with_device AS (
  SELECT
    t.fullVisitorId,
    t.first_tx_date,
    ANY_VALUE(s.device_category) AS device_category
  FROM first_tx               AS t
  JOIN feb_sessions           AS s
    ON  s.fullVisitorId = t.fullVisitorId
    AND s.session_date = t.first_tx_date
    AND s.transactions IS NOT NULL
    AND s.transactions > 0
  GROUP BY t.fullVisitorId, t.first_tx_date
)

SELECT
  tx.fullVisitorId,
  DATE_DIFF(tx.first_tx_date, v.first_visit_date, DAY) AS days_between_first_visit_and_first_transaction,
  tx.device_category                                   AS device_category_first_transaction
FROM first_tx_with_device AS tx
JOIN first_visit           AS v
  USING (fullVisitorId)
ORDER BY days_between_first_visit_and_first_transaction, fullVisitorId;
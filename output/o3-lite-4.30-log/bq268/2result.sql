WITH sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,                      -- session start (epoch seconds)
    device.isMobile   AS is_mobile,
    hits
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'      -- full range of the demo data
),

/* every individual transaction hit with the device flag of its session */
txn_hits AS (
  SELECT
    fullVisitorId,
    visitStartTime + h.time        AS txn_ts,
    is_mobile
  FROM sessions, UNNEST(hits) AS h
  WHERE h.transaction.transactionId IS NOT NULL
),

/* first transaction for every user (time & whether it was mobile) */
first_txn AS (
  SELECT
    fullVisitorId,
    ARRAY_AGG(txn_ts     ORDER BY txn_ts ASC LIMIT 1)[OFFSET(0)] AS first_txn_ts,
    ARRAY_AGG(is_mobile ORDER BY txn_ts ASC LIMIT 1)[OFFSET(0)] AS first_txn_is_mobile
  FROM txn_hits
  GROUP BY fullVisitorId
),

/* first visit, last visit (time & whether it was mobile) */
visits_summary AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_visit_ts,
    ARRAY_AGG(visitStartTime ORDER BY visitStartTime DESC LIMIT 1)[OFFSET(0)] AS last_visit_ts,
    ARRAY_AGG(is_mobile     ORDER BY visitStartTime DESC LIMIT 1)[OFFSET(0)] AS last_visit_is_mobile
  FROM sessions
  GROUP BY fullVisitorId
),

/* decide which of the two events is the “last recorded event” */
combined AS (
  SELECT
    v.fullVisitorId,
    v.first_visit_ts,
    CASE
        WHEN t.first_txn_ts IS NULL        -- user never purchased
             OR v.last_visit_ts >= t.first_txn_ts
             THEN v.last_visit_ts
        ELSE t.first_txn_ts
    END AS last_event_ts,
    CASE
        WHEN t.first_txn_ts IS NULL
             OR v.last_visit_ts >= t.first_txn_ts
             THEN v.last_visit_is_mobile
        ELSE t.first_txn_is_mobile
    END AS last_event_is_mobile
  FROM visits_summary v
  LEFT JOIN first_txn t
  USING (fullVisitorId)
)

/* keep only users whose last recorded event happened on a mobile device
   and return the one with the greatest span in days */
SELECT
  fullVisitorId AS user_id,
  DATE_DIFF(
      DATE(TIMESTAMP_SECONDS(last_event_ts)),
      DATE(TIMESTAMP_SECONDS(first_visit_ts)),
      DAY
  ) AS days_between_first_visit_and_last_mobile_event
FROM combined
WHERE last_event_is_mobile = TRUE
ORDER BY days_between_first_visit_and_last_mobile_event DESC,
         user_id
LIMIT 1;
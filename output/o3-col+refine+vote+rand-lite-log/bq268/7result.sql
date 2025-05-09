/*  Longest span (in days) between a user’s very first visit and their
    “last recorded event” (first transaction if one exists, otherwise the
    latest visit), where that last recorded event happened on a mobile device. */

WITH first_visit AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_visit_ts               -- earliest seen session
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
),

first_transaction AS (
  /* When a user has ≥1 transaction, keep the timestamp (and mobile flag)
     of their earliest such session.                                        */
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_trans_ts,
    ARRAY_AGG(device.isMobile ORDER BY visitStartTime ASC LIMIT 1)[OFFSET(0)]
        AS first_trans_mobile
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE totals.transactions > 0
  GROUP BY fullVisitorId
),

last_visit AS (
  /* Timestamp (and mobile flag) of the latest session we have for each user. */
  SELECT
    fullVisitorId,
    MAX(visitStartTime) AS last_visit_ts,
    ARRAY_AGG(device.isMobile ORDER BY visitStartTime DESC LIMIT 1)[OFFSET(0)]
        AS last_visit_mobile
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
),

user_timeline AS (
  /* Choose, per user, the “last recorded event” and its mobile flag. */
  SELECT
    fv.fullVisitorId,
    fv.first_visit_ts,
    COALESCE(ft.first_trans_ts, lv.last_visit_ts)         AS event_ts,
    COALESCE(ft.first_trans_mobile, lv.last_visit_mobile) AS event_mobile
  FROM first_visit fv
  LEFT JOIN first_transaction ft USING (fullVisitorId)
  JOIN last_visit lv USING (fullVisitorId)
)

SELECT
  fullVisitorId,
  ROUND( (event_ts - first_visit_ts) / 86400.0 , 2) AS days_between
FROM user_timeline
WHERE event_mobile = TRUE                                -- last event on mobile
QUALIFY days_between = MAX(days_between) OVER ()         -- longest span
;
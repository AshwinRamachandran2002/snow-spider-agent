/*  Longest span (in days) between a user’s first visit and their “last recorded event”
    (later of last session vs. first purchase),
    restricted to users whose last recorded event happened on a mobile device.
*/
WITH
-- (1) first visit date per user
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(PARSE_DATE('%Y%m%d', date)) AS first_visit_date
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
),

-- (2) latest session date + its mobile flag per user
last_session AS (
  SELECT
    fullVisitorId,
    ARRAY_AGG(
      STRUCT(
        PARSE_DATE('%Y%m%d', date) AS dt,
        device.isMobile           AS is_mobile
      )
      ORDER BY PARSE_DATE('%Y%m%d', date) DESC
      LIMIT 1
    )[OFFSET(0)] AS last_sess            -- struct with fields dt, is_mobile
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
),

-- (3) earliest purchase session date + its mobile flag per user
first_txn AS (
  SELECT
    fullVisitorId,
    ARRAY_AGG(
      STRUCT(
        PARSE_DATE('%Y%m%d', date) AS dt,
        device.isMobile           AS is_mobile
      )
      ORDER BY PARSE_DATE('%Y%m%d', date) ASC
      LIMIT 1
    )[OFFSET(0)] AS first_txn            -- struct with fields dt, is_mobile
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE totals.transactions IS NOT NULL
    AND totals.transactions > 0
  GROUP BY fullVisitorId
),

-- (4) choose later of latest session vs. first transaction
user_events AS (
  SELECT
    fv.fullVisitorId,
    fv.first_visit_date,
    CASE
      WHEN ft.first_txn IS NOT NULL
           AND ft.first_txn.dt > ls.last_sess.dt
      THEN ft.first_txn.dt
      ELSE ls.last_sess.dt
    END AS last_event_date,
    CASE
      WHEN ft.first_txn IS NOT NULL
           AND ft.first_txn.dt > ls.last_sess.dt
      THEN ft.first_txn.is_mobile
      ELSE ls.last_sess.is_mobile
    END AS last_event_is_mobile
  FROM first_visit  fv
  JOIN last_session ls ON fv.fullVisitorId = ls.fullVisitorId
  LEFT JOIN first_txn ft ON fv.fullVisitorId = ft.fullVisitorId
)

-- (5) maximum span where the last event is on mobile
SELECT
  MAX(DATE_DIFF(last_event_date, first_visit_date, DAY)) AS longest_days_between
FROM user_events
WHERE last_event_is_mobile = TRUE;
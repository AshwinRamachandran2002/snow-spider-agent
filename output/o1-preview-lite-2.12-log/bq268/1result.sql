WITH user_sessions AS (
  SELECT
    fullVisitorId,
    visitStartTime,
    device.isMobile AS isMobile,
    totals.transactions AS transactions
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),
user_first_last_visits AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_visit_time,
    MAX(visitStartTime) AS last_visit_time
  FROM
    user_sessions
  GROUP BY
    fullVisitorId
),
user_first_transaction AS (
  SELECT
    fullVisitorId,
    MIN(visitStartTime) AS first_transaction_time
  FROM
    user_sessions
  WHERE
    transactions > 0
  GROUP BY
    fullVisitorId
),
user_last_recorded_event AS (
  SELECT
    uflv.fullVisitorId,
    GREATEST(uflv.last_visit_time, IFNULL(uft.first_transaction_time, uflv.last_visit_time)) AS last_recorded_event_time
  FROM
    user_first_last_visits uflv
  LEFT JOIN
    user_first_transaction uft
  ON
    uflv.fullVisitorId = uft.fullVisitorId
),
user_last_event_mobile AS (
  SELECT
    ulre.fullVisitorId,
    ulre.last_recorded_event_time,
    ANY_VALUE(us.isMobile) AS isMobile
  FROM
    user_last_recorded_event ulre
  JOIN
    user_sessions us
  ON
    ulre.fullVisitorId = us.fullVisitorId
    AND ulre.last_recorded_event_time = us.visitStartTime
  GROUP BY
    ulre.fullVisitorId, ulre.last_recorded_event_time
),
user_durations AS (
  SELECT
    uflv.fullVisitorId,
    ROUND((ulre.last_recorded_event_time - uflv.first_visit_time) / 86400, 4) AS days_between_visits,
    ulre.isMobile
  FROM
    user_first_last_visits uflv
  JOIN
    user_last_event_mobile ulre
  ON
    uflv.fullVisitorId = ulre.fullVisitorId
  WHERE
    ulre.isMobile = TRUE
)
SELECT
  MAX(days_between_visits) AS Longest_number_of_days
FROM
  user_durations;
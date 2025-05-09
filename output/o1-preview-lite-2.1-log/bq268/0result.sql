SELECT
  MAX(days_between) AS Longest_number_of_days
FROM (
  WITH user_sessions AS (
    SELECT
      fullVisitorId,
      MIN(visitStartTime) AS first_visit,
      MAX(visitStartTime) AS last_visit,
      MIN(IF(totals.transactions > 0, visitStartTime, NULL)) AS first_transaction_time
    FROM
      `bigquery-public-data.google_analytics_sample.ga_sessions_*`
    GROUP BY
      fullVisitorId
  ),
  user_last_event AS (
    SELECT
      fullVisitorId,
      first_visit,
      IFNULL(first_transaction_time, last_visit) AS last_event_time,
      TIMESTAMP_DIFF(
        TIMESTAMP_SECONDS(IFNULL(first_transaction_time, last_visit)),
        TIMESTAMP_SECONDS(first_visit),
        DAY
      ) AS days_between
    FROM
      user_sessions
  ),
  user_last_event_mobile AS (
    SELECT
      ule.fullVisitorId,
      ule.days_between
    FROM
      user_last_event ule
    JOIN
      `bigquery-public-data.google_analytics_sample.ga_sessions_*` t
    ON
      t.fullVisitorId = ule.fullVisitorId
      AND t.visitStartTime = ule.last_event_time
    WHERE
      t.device.isMobile = TRUE
  )
  SELECT
    days_between
  FROM
    user_last_event_mobile
)
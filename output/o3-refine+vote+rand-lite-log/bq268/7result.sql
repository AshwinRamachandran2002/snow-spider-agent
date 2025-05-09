-- longest number of days between the first visit and the last recorded mobile event
WITH sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)              AS session_date,
    device.isMobile                         AS is_mobile,
    IFNULL(totals.transactions, 0)          AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

per_user AS (
  SELECT
    fullVisitorId,

    -- first ever visit (any device)
    MIN(session_date)                                                  AS first_visit_date,

    -- last visit that happened on a mobile device
    MAX(IF(is_mobile, session_date, NULL))                             AS mobile_last_visit_date,

    -- first (earliest) transaction that happened on a mobile device
    MIN(IF(is_mobile AND transactions > 0, session_date, NULL))        AS mobile_first_transaction_date
  FROM sessions
  GROUP BY fullVisitorId
),

event_dates AS (
  SELECT
    fullVisitorId,
    first_visit_date,

    -- choose the later of
    --   • last mobile visit
    --   • first mobile transaction
    -- (ignoring NULL values)
    (
      SELECT MAX(d)
      FROM UNNEST([
        mobile_last_visit_date,
        mobile_first_transaction_date
      ]) AS d
    ) AS last_event_date
  FROM per_user
),

qualified AS (
  -- keep only users whose last recorded event is on mobile
  SELECT
    fullVisitorId,
    DATE_DIFF(last_event_date, first_visit_date, DAY) AS days_between
  FROM event_dates
  WHERE last_event_date IS NOT NULL         -- must have a mobile event
)

SELECT
  days_between
FROM qualified
ORDER BY days_between DESC
LIMIT 1;
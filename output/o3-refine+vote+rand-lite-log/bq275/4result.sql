-- visitor IDs whose very first ecommerce transaction happened
-- on a session tagged as “mobile”, and that transaction took place
-- after (not on) the user’s very first visit
WITH sessions AS (
  SELECT
    fullVisitorId,
    PARSE_DATE('%Y%m%d', date)            AS session_date,
    IFNULL(totals.transactions, 0)        AS trans_cnt,
    device.isMobile                       AS is_mobile,
    device.deviceCategory                 AS device_category,
    visitStartTime                        AS visit_start_time
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
),

-- first ever visit for each user
first_visit AS (
  SELECT
    fullVisitorId,
    MIN(session_date) AS first_visit_date
  FROM sessions
  GROUP BY fullVisitorId
),

-- first ever transaction session for each user
first_transaction AS (
  SELECT
    fullVisitorId,
    session_date        AS first_trans_date,
    is_mobile,
    device_category
  FROM (
        SELECT
          fullVisitorId,
          session_date,
          is_mobile,
          device_category,
          ROW_NUMBER() OVER (
              PARTITION BY fullVisitorId
              ORDER BY session_date, visit_start_time
          ) AS rn
        FROM sessions
        WHERE trans_cnt > 0
  )
  WHERE rn = 1
)

SELECT DISTINCT
  ft.fullVisitorId
FROM first_transaction ft
JOIN first_visit fv
  ON ft.fullVisitorId = fv.fullVisitorId
WHERE ft.first_trans_date  > fv.first_visit_date           -- later than first visit
  AND (ft.device_category = 'mobile' OR ft.is_mobile = TRUE);
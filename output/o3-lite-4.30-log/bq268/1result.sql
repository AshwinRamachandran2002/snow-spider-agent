WITH sessions AS (
  SELECT
    fullVisitorId                           AS user_id,
    PARSE_DATE('%Y%m%d', date)              AS session_date,
    visitStartTime,
    device.isMobile                         AS is_mobile,
    totals.transactions                     AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
),
first_visit AS (
  SELECT
    user_id,
    MIN(session_date) AS first_visit_date
  FROM sessions
  GROUP BY user_id
),
first_tx AS (
  SELECT
    user_id,
    session_date  AS tx_date,
    is_mobile     AS tx_mobile,
    ROW_NUMBER() OVER (PARTITION BY user_id
                       ORDER BY session_date, visitStartTime) AS rn
  FROM sessions
  WHERE transactions > 0
),
first_tx_one AS (
  SELECT user_id, tx_date, tx_mobile
  FROM first_tx
  WHERE rn = 1
),
last_visit AS (
  SELECT
    user_id,
    session_date AS lv_date,
    is_mobile    AS lv_mobile,
    ROW_NUMBER() OVER (PARTITION BY user_id
                       ORDER BY session_date DESC, visitStartTime DESC) AS rn
  FROM sessions
),
last_visit_one AS (
  SELECT user_id, lv_date, lv_mobile
  FROM last_visit
  WHERE rn = 1
),
chosen_event AS (
  SELECT
    fv.user_id,
    fv.first_visit_date,
    COALESCE(ft.tx_date, lv.lv_date)       AS event_date,
    COALESCE(ft.tx_mobile, lv.lv_mobile)   AS event_is_mobile
  FROM first_visit      fv
  LEFT JOIN first_tx_one ft USING (user_id)
  LEFT JOIN last_visit_one lv USING (user_id)
),
mobile_users AS (
  SELECT
    user_id,
    DATE_DIFF(event_date, first_visit_date, DAY) AS days_between
  FROM chosen_event
  WHERE event_is_mobile = TRUE
)

SELECT
  user_id,
  days_between AS days_between_first_visit_and_last_mobile_event
FROM mobile_users
ORDER BY days_between DESC, user_id
LIMIT 1;
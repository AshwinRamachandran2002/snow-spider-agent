/*  Percentage of September‑2018 new users (first_open)
    who un‑installed the app within 7 days and, in that
    7‑day window, experienced at least one crash
    (event_name = 'app_exception')                                              */

WITH base AS (
  -- only the three event types we need and only the days that can participate
  SELECT
    user_pseudo_id,
    event_name,
    event_date,                       -- yyyymmdd string
    event_timestamp                   -- micro‑seconds since epoch
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181007'
    AND event_name IN ('first_open', 'app_remove', 'app_exception')
),

/* 1. First open in September 2018 */
first_open AS (
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date))            AS first_open_date,
    MIN(event_timestamp)                             AS first_open_ts
  FROM base
  WHERE event_name = 'first_open'
    AND event_date BETWEEN '20180901' AND '20180930'
  GROUP BY user_pseudo_id
),

/* 2. Uninstall (app_remove) that happened within 7 days after that first_open */
uninstall AS (
  SELECT
    fo.user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', b.event_date))  AS uninstall_date,
    MIN(b.event_timestamp)                   AS uninstall_ts
  FROM first_open fo
  JOIN base b
    ON fo.user_pseudo_id = b.user_pseudo_id
   AND b.event_name      = 'app_remove'
  WHERE PARSE_DATE('%Y%m%d', b.event_date)
        BETWEEN fo.first_open_date
            AND DATE_ADD(fo.first_open_date, INTERVAL 7 DAY)
  GROUP BY fo.user_pseudo_id
),

/* 3. Users who had at least one crash event between first_open and uninstall */
crash_users AS (
  SELECT DISTINCT fo.user_pseudo_id
  FROM first_open fo
  JOIN uninstall  u  USING (user_pseudo_id)
  JOIN base       b
    ON b.user_pseudo_id = fo.user_pseudo_id
   AND b.event_name     = 'app_exception'
   AND b.event_timestamp BETWEEN fo.first_open_ts AND u.uninstall_ts
)

/* 4. Final percentage */
SELECT
  SAFE_DIVIDE(
      (SELECT COUNT(*) FROM crash_users) ,
      (SELECT COUNT(*) FROM uninstall)
  ) * 100 AS percent_with_crash
;
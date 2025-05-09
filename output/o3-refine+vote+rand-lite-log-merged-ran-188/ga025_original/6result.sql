WITH first_open AS (
  -- Users whose very first “first_open” event happened in September 2018
  SELECT
    user_pseudo_id,
    TIMESTAMP_MICROS(MIN(event_timestamp)) AS first_open_ts          -- earliest first‑open in Sept
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180930'
    AND event_name = 'first_open'
  GROUP BY user_pseudo_id
),

uninstall AS (
  -- First uninstall (“app_remove”) for every user (only need up to 7 days past Sept)
  SELECT
    user_pseudo_id,
    TIMESTAMP_MICROS(MIN(event_timestamp)) AS uninstall_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181007'   -- Sept + 7 days
    AND event_name = 'app_remove'
  GROUP BY user_pseudo_id
),

qualified_uninstallers AS (
  -- Keep only users who uninstalled within 0‑7 days of first‑open
  SELECT
    fo.user_pseudo_id
  FROM first_open fo
  JOIN uninstall u
    ON fo.user_pseudo_id = u.user_pseudo_id
  WHERE DATE_DIFF(DATE(u.uninstall_ts), DATE(fo.first_open_ts), DAY) BETWEEN 0 AND 7
),

crashers AS (
  -- Users with at least one crash (“app_exception”) during the same overall period
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181007'
    AND event_name = 'app_exception'
)

SELECT
  ROUND( SAFE_DIVIDE(COUNT(c.user_pseudo_id), COUNT(q.user_pseudo_id)) * 100 , 4)
    AS percent_uninstallers_with_crash
FROM qualified_uninstallers q
LEFT JOIN crashers c
  ON q.user_pseudo_id = c.user_pseudo_id;
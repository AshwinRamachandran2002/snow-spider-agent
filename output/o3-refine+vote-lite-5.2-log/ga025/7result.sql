-- % of September‑2018 new users who uninstalled within 7 days
-- and, in that 7‑day lifetime, generated at least one crash (app_exception)

WITH all_events AS (
  SELECT
    user_pseudo_id,
    event_name,
    DATE(TIMESTAMP_MICROS(event_timestamp))              AS event_date,
    DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))   AS first_open_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20181007'     -- Sept first‑opens + 7‑day horizon
),

-- users whose first open happened in September‑2018
sept_first_open AS (
  SELECT DISTINCT user_pseudo_id, first_open_date
  FROM all_events
  WHERE first_open_date BETWEEN '2018-09-01' AND '2018-09-30'
),

-- first uninstall (app_remove) date for those users
first_uninstall AS (
  SELECT
    a.user_pseudo_id,
    MIN(a.event_date) AS uninstall_date
  FROM all_events a
  JOIN sept_first_open s
    ON s.user_pseudo_id = a.user_pseudo_id
  WHERE a.event_name = 'app_remove'
  GROUP BY a.user_pseudo_id
),

-- keep only users who uninstalled within 7 days of first open
uninstalled_within_7 AS (
  SELECT
    s.user_pseudo_id,
    s.first_open_date,
    u.uninstall_date
  FROM sept_first_open s
  JOIN first_uninstall u
    ON s.user_pseudo_id = u.user_pseudo_id
  WHERE DATE_DIFF(u.uninstall_date, s.first_open_date, DAY) BETWEEN 0 AND 7
),

-- among those users, who experienced at least one crash before uninstall
crashers AS (
  SELECT DISTINCT u.user_pseudo_id
  FROM uninstalled_within_7 u
  JOIN all_events a
    ON a.user_pseudo_id = u.user_pseudo_id
  WHERE a.event_name = 'app_exception'
    AND a.event_date BETWEEN u.first_open_date AND u.uninstall_date
)

SELECT
  ROUND(100 * COUNTIF(c.user_pseudo_id IS NOT NULL) / COUNT(*), 4) AS pct_with_crash
FROM uninstalled_within_7 u
LEFT JOIN crashers c
  ON u.user_pseudo_id = c.user_pseudo_id;
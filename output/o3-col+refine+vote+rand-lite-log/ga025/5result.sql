/*  Percentage of September-2018 first-touch users who un-installed
    within 7 days and, in that same 7-day window, experienced
    at least one crash (event_name = 'app_exception').
*/
WITH first_touch AS (         -- users whose very first touch was in Sept-2018
  SELECT
    user_pseudo_id,
    MIN(user_first_touch_timestamp) AS first_touch_ts          -- µs since epoch
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))
        BETWEEN '2018-09-01' AND '2018-09-30'
  GROUP BY user_pseudo_id
),
uninstall AS (                -- earliest uninstall for those users
  SELECT
    user_pseudo_id,
    MIN(event_timestamp)      AS uninstall_ts                  -- µs since epoch
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'app_remove'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM first_touch)
  GROUP BY user_pseudo_id
),
u7 AS (                       -- keep uninstalls that happened 0-7 days later
  SELECT
    f.user_pseudo_id,
    f.first_touch_ts,
    u.uninstall_ts
  FROM first_touch AS f
  JOIN uninstall   AS u USING (user_pseudo_id)
  WHERE DATE_DIFF(
          DATE(TIMESTAMP_MICROS(u.uninstall_ts)),
          DATE(TIMESTAMP_MICROS(f.first_touch_ts)),
          DAY) BETWEEN 0 AND 7
),
crash_in_7d AS (              -- users who crashed within the same 0-7-day span
  SELECT DISTINCT u.user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*` e
  JOIN u7                                          AS u USING (user_pseudo_id)
  WHERE e.event_name = 'app_exception'
    AND DATE(TIMESTAMP_MICROS(e.event_timestamp))
        BETWEEN DATE(TIMESTAMP_MICROS(u.first_touch_ts))
            AND DATE(TIMESTAMP_MICROS(u.first_touch_ts)) + 7
)
SELECT
  COUNT(DISTINCT c.user_pseudo_id)                              AS users_with_crash,
  COUNT(DISTINCT u.user_pseudo_id)                              AS total_uninstalled_within_7d,
  SAFE_DIVIDE(COUNT(DISTINCT c.user_pseudo_id),
              COUNT(DISTINCT u.user_pseudo_id)) * 100           AS pct_with_crash
FROM u7 AS u
LEFT JOIN crash_in_7d AS c
  ON u.user_pseudo_id = c.user_pseudo_id;
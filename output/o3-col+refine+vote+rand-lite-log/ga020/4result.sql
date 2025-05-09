-- Quick-play event with the lowest week-2 retention (Aug-01–Aug-15, 2018 cohort)
WITH cohort AS (   -- users’ first quick-play interaction inside the cohort window
  SELECT
    user_pseudo_id,
    event_name AS quickplay_event,
    PARSE_DATE('%Y%m%d', MIN(event_date)) AS cohort_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
    AND event_name LIKE '%quickplay%'
  GROUP BY user_pseudo_id, quickplay_event
),
session_starts AS (   -- all subsequent sessions for those users
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS sess_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180829'   -- covers week-2 horizon
    AND event_name = 'session_start'
)
SELECT
  c.quickplay_event,
  COUNT(DISTINCT c.user_pseudo_id)                                                          AS cohort_users,
  COUNT(DISTINCT CASE
                   WHEN s.sess_date BETWEEN DATE_ADD(c.cohort_date, INTERVAL 8  DAY)
                                       AND DATE_ADD(c.cohort_date, INTERVAL 14 DAY)
                   THEN c.user_pseudo_id END)                                              AS retained_users,
  SAFE_DIVIDE(
      COUNT(DISTINCT CASE
                       WHEN s.sess_date BETWEEN DATE_ADD(c.cohort_date, INTERVAL 8  DAY)
                                           AND DATE_ADD(c.cohort_date, INTERVAL 14 DAY)
                       THEN c.user_pseudo_id END),
      COUNT(DISTINCT c.user_pseudo_id))                                                    AS retention_rate
FROM cohort c
LEFT JOIN session_starts s
       ON c.user_pseudo_id = s.user_pseudo_id
GROUP BY c.quickplay_event
ORDER BY retention_rate ASC                -- lowest retention on top
LIMIT 1;
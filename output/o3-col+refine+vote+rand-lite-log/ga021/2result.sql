/*  Two–week retention (14-day) per quick-play event type
    – cohort: users whose FIRST quick-play event happened between 2-Jul-18 and 16-Jul-18
    – only users who had at least one session_start in that same period are considered
    – retained: user generated ANY event exactly 14 days after that first quick-play time          */

WITH session_users AS (           -- users who started a session in the period
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND event_name = 'session_start'
),

first_quickplay AS (             -- first quick-play hit for each user & quick-play event type
  SELECT
    user_pseudo_id,
    event_name                         AS quickplay_event,
    MIN(event_timestamp)               AS first_ts
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20180716'
    AND LOWER(event_name) LIKE '%quickplay%'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM session_users)
  GROUP BY user_pseudo_id, quickplay_event
),

retained_users AS (              -- users seen exactly 14 days after their first quick-play hit
  SELECT DISTINCT
    fq.user_pseudo_id,
    fq.quickplay_event
  FROM first_quickplay AS fq
  JOIN `firebase-public-project.analytics_153293282.events_*` AS ev
    ON ev.user_pseudo_id = fq.user_pseudo_id
  WHERE DATE(TIMESTAMP_MICROS(ev.event_timestamp))
        = DATE_ADD(DATE(TIMESTAMP_MICROS(fq.first_ts)), INTERVAL 14 DAY)
)

SELECT
  fq.quickplay_event,
  COUNT(DISTINCT ru.user_pseudo_id)               AS retained_users,
  COUNT(DISTINCT fq.user_pseudo_id)               AS cohort_users,
  ROUND(COUNT(DISTINCT ru.user_pseudo_id)
        / COUNT(DISTINCT fq.user_pseudo_id), 4)   AS two_week_retention_rate
FROM first_quickplay AS fq
LEFT JOIN retained_users AS ru
  ON  ru.user_pseudo_id  = fq.user_pseudo_id
  AND ru.quickplay_event = fq.quickplay_event
GROUP BY fq.quickplay_event
ORDER BY two_week_retention_rate DESC;
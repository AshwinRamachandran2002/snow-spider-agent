-- Quick-Play event type with the lowest week-2 retention rate
WITH cohort AS (
  -- users’ first Quick-Play engagement between 1–15 Aug 2018
  SELECT
    event_name,
    user_pseudo_id,
    MIN(TIMESTAMP_MICROS(event_timestamp)) AS first_eng_ts
  FROM
    `firebase-public-project.analytics_153293282.events_201808*`
  WHERE
    event_name IN ('level_start_quickplay',
                   'level_complete_quickplay',
                   'level_fail_quickplay')
    AND event_date BETWEEN '20180801' AND '20180815'
  GROUP BY
    event_name,
    user_pseudo_id
),
retained AS (
  -- those cohort users who had ≥1 session_start 8-14 days later
  SELECT DISTINCT
    c.event_name,
    c.user_pseudo_id
  FROM
    cohort c
  JOIN
    `firebase-public-project.analytics_153293282.events_201808*` e
  ON  e.user_pseudo_id = c.user_pseudo_id
  WHERE
    e.event_name = 'session_start'
    AND DATE_DIFF(DATE(TIMESTAMP_MICROS(e.event_timestamp)),
                  DATE(c.first_eng_ts), DAY) BETWEEN 8 AND 14
)
SELECT
  coh.event_name                                              AS quickplay_event_type,
  COUNT(DISTINCT coh.user_pseudo_id)                          AS cohort_size,
  COUNT(DISTINCT ret.user_pseudo_id)                          AS retained_users,
  SAFE_DIVIDE(COUNT(DISTINCT ret.user_pseudo_id),
              COUNT(DISTINCT coh.user_pseudo_id))             AS week2_retention_rate
FROM
  cohort coh
LEFT JOIN
  retained ret
ON  coh.event_name     = ret.event_name
AND coh.user_pseudo_id = ret.user_pseudo_id
GROUP BY
  quickplay_event_type
ORDER BY
  week2_retention_rate ASC
LIMIT 1;
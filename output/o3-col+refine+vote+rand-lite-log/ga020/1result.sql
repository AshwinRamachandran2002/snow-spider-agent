-- Which quick-play event type has the lowest week-2 retention rate?
WITH cohort AS (
  /* users’ first quick-play event between Aug-01 and Aug-15, 2018 */
  SELECT
    event_name                            AS quickplay_event,
    user_pseudo_id,
    MIN( PARSE_DATE('%Y%m%d', event_date) ) AS cohort_start_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
    AND LOWER(event_name) LIKE '%quickplay%'
  GROUP BY quickplay_event, user_pseudo_id
),
sessions AS (
  /* all sessions in August-18 used for retention check */
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS session_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180831'
    AND event_name = 'session_start'
),
retention AS (
  /* flag users who returned 8-14 days after cohort start */
  SELECT
    c.quickplay_event,
    c.user_pseudo_id,
    COUNTIF(
      DATE_DIFF(s.session_date, c.cohort_start_date, DAY) BETWEEN 8 AND 14
    ) > 0 AS retained_week2
  FROM cohort AS c
  LEFT JOIN sessions AS s
    ON c.user_pseudo_id = s.user_pseudo_id
  GROUP BY c.quickplay_event, c.user_pseudo_id
)
SELECT
  quickplay_event                                   AS event_type,
  COUNT(DISTINCT user_pseudo_id)                    AS cohort_users,
  COUNTIF(retained_week2)                           AS retained_users,
  SAFE_DIVIDE(COUNTIF(retained_week2),
              COUNT(DISTINCT user_pseudo_id))       AS week2_retention_rate
FROM retention
GROUP BY quickplay_event
ORDER BY week2_retention_rate ASC
LIMIT 1;
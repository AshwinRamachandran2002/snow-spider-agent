/*  Week‑2 retention for weekly cohorts (Mon‑Sun) between
    9 Jul 2018 and 17 Sep 2018 in the GA4 public game dataset           */

WITH session_events AS (
  -- all session_start events in the period we care about
  SELECT
      user_pseudo_id,
      PARSE_DATE('%Y%m%d', event_date)                       AS event_date,
      DATE(TIMESTAMP_MICROS(user_first_touch_timestamp))     AS first_touch_date
  FROM  `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'      -- tables to read
    AND event_name = 'session_start'
),

/* -------------------------------------------------------------------- */
/*  1. New users = session_start events whose event_date is the user’s  */
/*     first‑touch day.  Keep only cohorts we can evaluate (≤17 Sep).   */
new_user_sessions AS (
  SELECT DISTINCT
         user_pseudo_id,
         event_date                                         AS first_session_date
  FROM   session_events
  WHERE  event_date = first_touch_date
    AND  event_date BETWEEN '2018-07-09' AND '2018-09-17'
),

/*  2. Assign each new user to the Monday that starts her first week.   */
cohorts AS (
  SELECT
      user_pseudo_id,
      DATE_TRUNC(first_session_date, WEEK(MONDAY))          AS cohort_week_start
  FROM  new_user_sessions
),

/*  3. For every user, list the weeks (Mon) in which she was active.    */
user_weeks AS (
  SELECT DISTINCT
      user_pseudo_id,
      DATE_TRUNC(event_date, WEEK(MONDAY))                   AS active_week_start
  FROM  session_events
)

/*  4. Week‑2 retention calculation                                    */
SELECT
    cohort_week_start                                        AS cohort_week,
    COUNT(DISTINCT user_pseudo_id)                           AS cohort_size,
    COUNT(DISTINCT CASE
                     WHEN DATE_DIFF(active_week_start,
                                     cohort_week_start,
                                     WEEK(MONDAY)) = 2
                     THEN user_pseudo_id
                   END)                                      AS retained_users,
    ROUND(
      100 * SAFE_DIVIDE(
              COUNT(DISTINCT CASE
                               WHEN DATE_DIFF(active_week_start,
                                               cohort_week_start,
                                               WEEK(MONDAY)) = 2
                               THEN user_pseudo_id
                             END),
              COUNT(DISTINCT user_pseudo_id)
      ), 2)                                                  AS week2_retention_percentage
FROM cohorts
LEFT JOIN user_weeks
USING (user_pseudo_id)
GROUP BY cohort_week_start
ORDER BY cohort_week_start;
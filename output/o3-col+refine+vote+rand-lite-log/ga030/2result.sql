WITH sessions AS (
  /* every session_start from the raw GA4 export                          */
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS event_dt
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
),

first_session AS (
  /* first-ever session on/after 2018-07-02 for each user                  */
  SELECT
    user_pseudo_id,
    MIN(event_dt) AS first_session_date
  FROM sessions
  WHERE event_dt >= DATE '2018-07-02'
  GROUP BY user_pseudo_id
),

cohort_label AS (
  /* label users by the Monday of the week of their first session          */
  SELECT
    user_pseudo_id,
    DATE_TRUNC(first_session_date, WEEK(MONDAY)) AS cohort_monday
  FROM first_session
),

week4_flags AS (
  /* did the user return with a session_start during days 21-27?           */
  SELECT
    c.user_pseudo_id,
    c.cohort_monday,
    COUNTIF(
      s.event_dt BETWEEN c.cohort_monday + INTERVAL 21 DAY
                  AND   c.cohort_monday + INTERVAL 27 DAY
    ) > 0 AS week4_returned
  FROM cohort_label AS c
  JOIN sessions    AS s
    USING (user_pseudo_id)
  GROUP BY c.user_pseudo_id, c.cohort_monday
),

cohort_retention AS (
  /* fourth-week retention rate for every Monday cohort                    */
  SELECT
    cohort_monday,
    SAFE_DIVIDE(
      SUM(CASE WHEN week4_returned THEN 1 END),
      COUNT(*)
    ) AS week4_retention
  FROM week4_flags
  GROUP BY cohort_monday
)

/* ----- final answer: cohort (Monday) with the best week-4 retention ----- */
SELECT
  FORMAT_DATE('%Y-%m-%d', cohort_monday) AS best_cohort_monday
FROM cohort_retention
ORDER BY week4_retention DESC
LIMIT 1;
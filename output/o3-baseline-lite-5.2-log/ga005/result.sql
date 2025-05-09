-- Week‑2 retention per weekly cohort (Mon‑Sun)  
-- Google GA4 public gaming dataset  
-- Cohorts: users whose 1st session_start happened in the week and
--          whose event_date = user_first_touch_date  
-- Week‑2 retention: had at least one session_start 14‑20 days later  

WITH session_events AS (          -- 1. pull only the needed rows
    SELECT
        PARSE_DATE('%Y%m%d', event_date)          AS event_dt,     -- to DATE
        user_pseudo_id,
        user_first_touch_timestamp,
        event_name
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE _TABLE_SUFFIX BETWEEN '20180709' AND '20181002'          -- whole period we need
      AND event_name = 'session_start'
),

new_user_sessions AS (            -- 2. sessions that are on the user’s first‑touch day
    SELECT
        user_pseudo_id,
        event_dt,
        DATE_TRUNC(event_dt, WEEK(MONDAY))        AS cohort_week_start
    FROM session_events
    WHERE FORMAT_DATE('%Y%m%d', event_dt)
          = FORMAT_DATE('%Y%m%d', DATE(TIMESTAMP_MICROS(user_first_touch_timestamp)))
),

cohorts AS (                      -- 3. keep cohorts we can evaluate for week‑2 retention
    SELECT DISTINCT
        user_pseudo_id,
        cohort_week_start
    FROM new_user_sessions
    WHERE cohort_week_start BETWEEN DATE '2018-07-09' AND DATE '2018-09-17'
),

cohort_sizes AS (                 -- 4. size of every cohort
    SELECT
        cohort_week_start,
        COUNT(DISTINCT user_pseudo_id) AS cohort_users
    FROM cohorts
    GROUP BY cohort_week_start
),

retained_users AS (               -- 5. users active again 14‑20 days later
    SELECT DISTINCT
        c.cohort_week_start,
        c.user_pseudo_id
    FROM cohorts  AS c
    JOIN session_events AS s
      ON s.user_pseudo_id = c.user_pseudo_id
     AND s.event_dt BETWEEN c.cohort_week_start + 14   -- Monday two weeks later
                        AND     c.cohort_week_start + 20   -- through Sunday
),

retention_counts AS (             -- 6. retained user counts
    SELECT
        cohort_week_start,
        COUNT(DISTINCT user_pseudo_id) AS retained_users
    FROM retained_users
    GROUP BY cohort_week_start
)

-- 7. final result -----------------------------------------------------
SELECT
    cohort_week_start                       AS cohort_monday,
    SAFE_DIVIDE(retained_users, cohort_users) AS week2_retention_rate
FROM cohort_sizes
LEFT JOIN retention_counts USING (cohort_week_start)
ORDER BY cohort_week_start;
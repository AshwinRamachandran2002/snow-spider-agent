/* ------------------------------------------------------------
   Weekly “Week-2” retention for GA4 public gaming dataset
   Cohorts: every Monday from 09-Jul-2018 through 17-Sep-2018
   Week-2 return: user has a session_start exactly 14 days later
-------------------------------------------------------------*/
WITH
/* 1. session_start events for every Monday cohort date
      and the corresponding Monday exactly 2 weeks later     */
session_events AS (

    /* ---------- 09-Jul-2018 ---------- */
    SELECT "user_pseudo_id",
           "event_date",
           "user_first_touch_timestamp"
    FROM   FIREBASE.ANALYTICS_153293282."EVENTS_20180709"
    WHERE  "event_name" = 'session_start'

    UNION ALL
    /* ---------- 16-Jul-2018 ---------- */
    SELECT "user_pseudo_id",
           "event_date",
           "user_first_touch_timestamp"
    FROM   FIREBASE.ANALYTICS_153293282."EVENTS_20180716"
    WHERE  "event_name" = 'session_start'

    UNION ALL
    /* ---------- 23-Jul-2018 ---------- */
    SELECT "user_pseudo_id",
           "event_date",
           "user_first_touch_timestamp"
    FROM   FIREBASE.ANALYTICS_153293282."EVENTS_20180723"
    WHERE  "event_name" = 'session_start'

    UNION ALL
    /* ---------- 30-Jul-2018 ---------- */
    SELECT "user_pseudo_id",
           "event_date",
           "user_first_touch_timestamp"
    FROM   FIREBASE.ANALYTICS_153293282."EVENTS_20180730"
    WHERE  "event_name" = 'session_start'

    UNION ALL
    /* ---------- 06-Aug-2018 ---------- */
    SELECT "user_pseudo_id",
           "event_date",
           "user_first_touch_timestamp"
    FROM   FIREBASE.ANALYTICS_153293282."EVENTS_20180806"
    WHERE  "event_name" = 'session_start'

    UNION ALL
    /* ---------- 13-Aug-2018 ---------- */
    SELECT "user_pseudo_id",
           "event_date",
           "user_first_touch_timestamp"
    FROM   FIREBASE.ANALYTICS_153293282."EVENTS_20180813"
    WHERE  "event_name" = 'session_start'

    UNION ALL
    /* ---------- 20-Aug-2018 ---------- */
    SELECT "user_pseudo_id",
           "event_date",
           "user_first_touch_timestamp"
    FROM   FIREBASE.ANALYTICS_153293282."EVENTS_20180820"
    WHERE  "event_name" = 'session_start'

    UNION ALL
    /* ---------- 27-Aug-2018 ---------- */
    SELECT "user_pseudo_id",
           "event_date",
           "user_first_touch_timestamp"
    FROM   FIREBASE.ANALYTICS_153293282."EVENTS_20180827"
    WHERE  "event_name" = 'session_start'

    UNION ALL
    /* ---------- 03-Sep-2018 ---------- */
    SELECT "user_pseudo_id",
           "event_date",
           "user_first_touch_timestamp"
    FROM   FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
    WHERE  "event_name" = 'session_start'

    UNION ALL
    /* ---------- 10-Sep-2018 ---------- */
    SELECT "user_pseudo_id",
           "event_date",
           "user_first_touch_timestamp"
    FROM   FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
    WHERE  "event_name" = 'session_start'

    UNION ALL
    /* ---------- 17-Sep-2018 ---------- */
    SELECT "user_pseudo_id",
           "event_date",
           "user_first_touch_timestamp"
    FROM   FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
    WHERE  "event_name" = 'session_start'

    /* ---------- RETURN-WEEK TABLES (14-day later) ---------- */
    UNION ALL  /* 24-Sep-2018 */
    SELECT "user_pseudo_id",
           "event_date",
           "user_first_touch_timestamp"
    FROM   FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
    WHERE  "event_name" = 'session_start'

    UNION ALL  /* 01-Oct-2018 */
    SELECT "user_pseudo_id",
           "event_date",
           "user_first_touch_timestamp"
    FROM   FIREBASE.ANALYTICS_153293282."EVENTS_20181001"
    WHERE  "event_name" = 'session_start'
),

/* 2. Convert the user_first_touch timestamp to yyyymmdd text */
session_events_touched AS (
    SELECT
        "user_pseudo_id",
        "event_date",
        TO_VARCHAR(
            DATEADD(
                second,
                ("user_first_touch_timestamp" / 1000000),   -- micro->seconds
                '1970-01-01'::timestamp
            ),
            'YYYYMMDD'
        ) AS first_touch_date
    FROM session_events
),

/* 3. Identify each user’s FIRST session_start date (their cohort date) */
first_sessions AS (
    SELECT
        "user_pseudo_id",
        MIN("event_date") AS cohort_date,
        MIN(first_touch_date) AS first_touch_date
    FROM   session_events_touched
    GROUP  BY "user_pseudo_id"
),

/* 4. Keep only users whose cohort day equals their first-touch day
      and whose cohort Monday lies between 09-Jul-2018 and 17-Sep-2018 */
cohort_users AS (
    SELECT
        "user_pseudo_id",
        cohort_date                        AS cohort_yyyymmdd,
        TO_DATE(cohort_date,'YYYYMMDD')    AS cohort_day
    FROM   first_sessions
    WHERE  cohort_date = first_touch_date                  -- new users
      AND  cohort_date BETWEEN '20180709' AND '20180917'   -- required cohorts
),

/* 5. Mark those users that returned exactly 14 days later */
returns AS (
    SELECT DISTINCT
           se."user_pseudo_id",
           se."event_date"
    FROM   session_events_touched se
),

cohort_with_flags AS (
    SELECT
        cu.cohort_yyyymmdd                                  AS cohort_date,
        cu."user_pseudo_id",
        CASE
           WHEN EXISTS (
                    SELECT 1
                    FROM   returns r
                    WHERE  r."user_pseudo_id" = cu."user_pseudo_id"
                      AND  r."event_date" = TO_VARCHAR(
                              DATEADD(day,14,cu.cohort_day),
                              'YYYYMMDD'
                          )
                )
           THEN 1 ELSE 0
        END AS returned_week2
    FROM   cohort_users cu
)

/* 6. Aggregate for each weekly cohort */
SELECT
    cohort_date,
    COUNT(*)                                    AS cohort_size,
    SUM(returned_week2)                         AS week2_returners,
    ROUND(100.0 * SUM(returned_week2) / COUNT(*), 2) AS week2_retention_rate_pct
FROM   cohort_with_flags
GROUP  BY cohort_date
ORDER  BY cohort_date;
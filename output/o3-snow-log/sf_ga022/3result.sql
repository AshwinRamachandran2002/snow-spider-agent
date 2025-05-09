/* ---------------------------------------------------------------
   Weekly retention (weeks 1-3) for users whose very first
   “first_open” occurred 1-7 Sep 2018 (Shanghai time, UTC+8)
---------------------------------------------------------------- */
WITH cohort_source AS (           /* first-open events 1-7 Sep 2018 */
    SELECT "user_pseudo_id",
           "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180901"
    WHERE "event_name" = 'first_open'
    UNION ALL SELECT "user_pseudo_id","event_timestamp"
               FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180902"
               WHERE "event_name" = 'first_open'
    UNION ALL SELECT "user_pseudo_id","event_timestamp"
               FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180903"
               WHERE "event_name" = 'first_open'
    UNION ALL SELECT "user_pseudo_id","event_timestamp"
               FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180904"
               WHERE "event_name" = 'first_open'
    UNION ALL SELECT "user_pseudo_id","event_timestamp"
               FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180905"
               WHERE "event_name" = 'first_open'
    UNION ALL SELECT "user_pseudo_id","event_timestamp"
               FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180906"
               WHERE "event_name" = 'first_open'
    UNION ALL SELECT "user_pseudo_id","event_timestamp"
               FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180907"
               WHERE "event_name" = 'first_open'
),
cohort_users AS (                 /* keep earliest install per user */
    SELECT
        "user_pseudo_id",
        MIN("event_timestamp") AS "first_open_ts"
    FROM cohort_source
    GROUP BY "user_pseudo_id"
    HAVING DATE(
              CONVERT_TIMEZONE(
                  'UTC','Asia/Shanghai',
                  TO_TIMESTAMP("first_open_ts"/1000000)
              )
           ) BETWEEN '2018-09-01' AND '2018-09-07'
),
/* ---------------- all September-18 events for retention --------- */
all_events AS (
      SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180901"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180902"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180903"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180904"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180905"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180906"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180907"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180908"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180909"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180910"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180911"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180912"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180913"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180914"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180915"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180916"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180917"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180918"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180919"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180920"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180921"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180922"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180923"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180924"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180925"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180926"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180927"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180928"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180929"
 UNION ALL SELECT * FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180930"
),
/* ---------------- map each user event to week offset ------------- */
retention AS (
    SELECT
        cu."user_pseudo_id",
        FLOOR(
            DATEDIFF(
                'day',
                DATE(CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                     TO_TIMESTAMP(cu."first_open_ts"/1000000))),
                DATE(CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                     TO_TIMESTAMP(ae."event_timestamp"/1000000)))
            ) / 7
        ) + 1 AS week_no
    FROM all_events ae
    JOIN cohort_users cu
          ON ae."user_pseudo_id" = cu."user_pseudo_id"
    WHERE ae."event_timestamp" > cu."first_open_ts"                -- exclude day 0
      AND DATEDIFF(
            'day',
            DATE(CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                 TO_TIMESTAMP(cu."first_open_ts"/1000000))),
            DATE(CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                 TO_TIMESTAMP(ae."event_timestamp"/1000000)))
          ) BETWEEN 1 AND 21                                        -- weeks 1-3
),
weekly_counts AS (                     /* retained users per week */
    SELECT
        week_no,
        COUNT(DISTINCT "user_pseudo_id") AS retained_users
    FROM retention
    WHERE week_no IN (1,2,3)
    GROUP BY week_no
),
cohort_size AS (                       /* cohort denominator */
    SELECT COUNT(DISTINCT "user_pseudo_id") AS total_users
    FROM cohort_users
)
/* --------------------------- output ----------------------------- */
SELECT
    ROUND( COALESCE((SELECT retained_users FROM weekly_counts WHERE week_no = 1),0)
           / cs.total_users::FLOAT , 4)  AS "week1_retention",
    ROUND( COALESCE((SELECT retained_users FROM weekly_counts WHERE week_no = 2),0)
           / cs.total_users::FLOAT , 4)  AS "week2_retention",
    ROUND( COALESCE((SELECT retained_users FROM weekly_counts WHERE week_no = 3),0)
           / cs.total_users::FLOAT , 4)  AS "week3_retention"
FROM cohort_size cs;
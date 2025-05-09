/* Weekly retention (weeks 1-3) for users whose very first
   “first_open” event occurred 1 – 7 Sep 2018 (Asia/Shanghai) */

WITH "ALL_EVENTS" AS (               /* --------  Sept-2018 raw events  -------- */
    SELECT * FROM (
        SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180901"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180902"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180903"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180904"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180905"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180906"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180907"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180908"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180909"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180910"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180911"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180912"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180913"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180914"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180916"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180917"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180918"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180919"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180920"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180921"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180922"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180923"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180924"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180925"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180926"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180927"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180928"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180929"
        UNION ALL SELECT * FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180930"
    )
),

/* --------  Cohort: first-time users (1-7 Sep)  -------- */
"COHORT" AS (
    SELECT
        "user_pseudo_id",
        TO_DATE(
            CONVERT_TIMEZONE(
                'UTC','Asia/Shanghai',
                TO_TIMESTAMP(MIN("event_timestamp")/1000000)
            )
        ) AS "cohort_date"
    FROM "ALL_EVENTS"
    WHERE "event_name" = 'first_open'
      AND TO_DATE(
              CONVERT_TIMEZONE(
                  'UTC','Asia/Shanghai',
                  TO_TIMESTAMP("event_timestamp"/1000000)
              )
          ) BETWEEN '2018-09-01' AND '2018-09-07'
    GROUP BY "user_pseudo_id"
),

/* --------  Subsequent events for those cohort users  -------- */
"RET_EVENTS" AS (
    SELECT
        c."user_pseudo_id",
        CASE
            WHEN DATEDIFF('day', c."cohort_date",
                          TO_DATE(CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                                 TO_TIMESTAMP(a."event_timestamp"/1000000))))
                 BETWEEN 1  AND 7  THEN 1
            WHEN DATEDIFF('day', c."cohort_date",
                          TO_DATE(CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                                 TO_TIMESTAMP(a."event_timestamp"/1000000))))
                 BETWEEN 8  AND 14 THEN 2
            WHEN DATEDIFF('day', c."cohort_date",
                          TO_DATE(CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                                 TO_TIMESTAMP(a."event_timestamp"/1000000))))
                 BETWEEN 15 AND 21 THEN 3
        END AS "week_num"
    FROM "ALL_EVENTS" a
    JOIN "COHORT"    c
      ON a."user_pseudo_id" = c."user_pseudo_id"
    WHERE
        CASE
            WHEN DATEDIFF('day', c."cohort_date",
                          TO_DATE(CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                                 TO_TIMESTAMP(a."event_timestamp"/1000000))))
                 BETWEEN 1  AND 7  THEN 1
            WHEN DATEDIFF('day', c."cohort_date",
                          TO_DATE(CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                                 TO_TIMESTAMP(a."event_timestamp"/1000000))))
                 BETWEEN 8  AND 14 THEN 2
            WHEN DATEDIFF('day', c."cohort_date",
                          TO_DATE(CONVERT_TIMEZONE('UTC','Asia/Shanghai',
                                 TO_TIMESTAMP(a."event_timestamp"/1000000))))
                 BETWEEN 15 AND 21 THEN 3
        END IS NOT NULL
),

/* --------  Distinct returning users by week  -------- */
"RETENTION" AS (
    SELECT
        "week_num",
        COUNT(DISTINCT "user_pseudo_id") AS "retained_users"
    FROM "RET_EVENTS"
    GROUP BY "week_num"
),

"COHORT_SIZE" AS (
    SELECT COUNT(DISTINCT "user_pseudo_id") AS "users_in_cohort"
    FROM "COHORT"
)

/* --------  Final retention output  -------- */
SELECT
    ROUND(
        COALESCE(MAX(CASE WHEN "week_num" = 1 THEN "retained_users" END), 0)
        / MAX("users_in_cohort"), 4
    ) AS "WEEK1_RETENTION",
    ROUND(
        COALESCE(MAX(CASE WHEN "week_num" = 2 THEN "retained_users" END), 0)
        / MAX("users_in_cohort"), 4
    ) AS "WEEK2_RETENTION",
    ROUND(
        COALESCE(MAX(CASE WHEN "week_num" = 3 THEN "retained_users" END), 0)
        / MAX("users_in_cohort"), 4
    ) AS "WEEK3_RETENTION"
FROM "RETENTION"
CROSS JOIN "COHORT_SIZE";
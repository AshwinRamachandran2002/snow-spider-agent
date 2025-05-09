WITH 
cohort_users AS (
    SELECT DISTINCT "user_pseudo_id"
    FROM (
        SELECT "user_pseudo_id", "user_first_touch_timestamp"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180901"
        UNION ALL
        SELECT "user_pseudo_id", "user_first_touch_timestamp"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180902"
        UNION ALL
        SELECT "user_pseudo_id", "user_first_touch_timestamp"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180903"
        UNION ALL
        SELECT "user_pseudo_id", "user_first_touch_timestamp"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180904"
        UNION ALL
        SELECT "user_pseudo_id", "user_first_touch_timestamp"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180905"
        UNION ALL
        SELECT "user_pseudo_id", "user_first_touch_timestamp"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180906"
        UNION ALL
        SELECT "user_pseudo_id", "user_first_touch_timestamp"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180907"
    ) AS cohort
    WHERE "user_first_touch_timestamp" >= ((DATE_PART(EPOCH_SECOND, TO_TIMESTAMP_NTZ('2018-08-31 16:00:00', 'YYYY-MM-DD HH24:MI:SS'))) * 1000000)
      AND "user_first_touch_timestamp" < ((DATE_PART(EPOCH_SECOND, TO_TIMESTAMP_NTZ('2018-09-07 16:00:00', 'YYYY-MM-DD HH24:MI:SS'))) * 1000000)
),
events_weeks AS (
    SELECT DISTINCT "user_pseudo_id", 1 AS week
    FROM (
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180908"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180909"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180910"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180911"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180912"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180913"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180914"
    ) AS week1
    WHERE "user_pseudo_id" IN (SELECT "user_pseudo_id" FROM cohort_users)
    UNION ALL
    SELECT DISTINCT "user_pseudo_id", 2 AS week
    FROM (
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180915"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180916"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180917"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180918"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180919"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180920"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180921"
    ) AS week2
    WHERE "user_pseudo_id" IN (SELECT "user_pseudo_id" FROM cohort_users)
    UNION ALL
    SELECT DISTINCT "user_pseudo_id", 3 AS week
    FROM (
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180922"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180923"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180924"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180925"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180926"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180927"
        UNION ALL
        SELECT "user_pseudo_id" FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180928"
    ) AS week3
    WHERE "user_pseudo_id" IN (SELECT "user_pseudo_id" FROM cohort_users)
),
retention AS (
    SELECT week, COUNT(DISTINCT "user_pseudo_id") AS returning_users
    FROM events_weeks
    GROUP BY week
),
total_users AS (
    SELECT COUNT(DISTINCT "user_pseudo_id") AS total_users FROM cohort_users
)
SELECT 
    CONCAT('Week ', CAST(week AS VARCHAR)) AS "Week", 
    ROUND((retention.returning_users / total_users.total_users) * 100, 4) AS "Retention_Rate"
FROM retention, total_users
ORDER BY week;
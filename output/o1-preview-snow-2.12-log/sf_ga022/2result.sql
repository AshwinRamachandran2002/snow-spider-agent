WITH
new_users AS (
    SELECT DISTINCT "user_pseudo_id"
    FROM (
        SELECT "user_pseudo_id"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180901" WHERE "event_name" = 'first_open'
        UNION ALL
        SELECT "user_pseudo_id"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180902" WHERE "event_name" = 'first_open'
        UNION ALL
        SELECT "user_pseudo_id"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180903" WHERE "event_name" = 'first_open'
        UNION ALL
        SELECT "user_pseudo_id"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180904" WHERE "event_name" = 'first_open'
        UNION ALL
        SELECT "user_pseudo_id"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180905" WHERE "event_name" = 'first_open'
        UNION ALL
        SELECT "user_pseudo_id"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180906" WHERE "event_name" = 'first_open'
        UNION ALL
        SELECT "user_pseudo_id"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180907" WHERE "event_name" = 'first_open'
    )
),
total_new_users AS (
    SELECT COUNT(DISTINCT "user_pseudo_id") AS total_new_users FROM new_users
)
SELECT '1' AS "Week",
       ROUND((COUNT(DISTINCT week1_events."user_pseudo_id") * 100.0 / (SELECT total_new_users FROM total_new_users)),4) AS "Retention_Rate"
FROM new_users
JOIN (
    SELECT DISTINCT "user_pseudo_id"
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
    ) AS week1_events
) AS week1_events ON new_users."user_pseudo_id" = week1_events."user_pseudo_id"
UNION ALL
SELECT '2' AS "Week",
       ROUND((COUNT(DISTINCT week2_events."user_pseudo_id") * 100.0 / (SELECT total_new_users FROM total_new_users)),4) AS "Retention_Rate"
FROM new_users
JOIN (
    SELECT DISTINCT "user_pseudo_id"
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
    ) AS week2_events
) AS week2_events ON new_users."user_pseudo_id" = week2_events."user_pseudo_id"
UNION ALL
SELECT '3' AS "Week",
       ROUND((COUNT(DISTINCT week3_events."user_pseudo_id") * 100.0 / (SELECT total_new_users FROM total_new_users)),4) AS "Retention_Rate"
FROM new_users
JOIN (
    SELECT DISTINCT "user_pseudo_id"
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
    ) AS week3_events
) AS week3_events ON new_users."user_pseudo_id" = week3_events."user_pseudo_id"
ORDER BY "Week";
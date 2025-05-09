WITH cohort_users AS (
    SELECT DISTINCT "user_pseudo_id"
    FROM (
        SELECT "user_pseudo_id", "event_name"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180901
        UNION ALL
        SELECT "user_pseudo_id", "event_name"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180902
        UNION ALL
        SELECT "user_pseudo_id", "event_name"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180903
        UNION ALL
        SELECT "user_pseudo_id", "event_name"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180904
        UNION ALL
        SELECT "user_pseudo_id", "event_name"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180905
        UNION ALL
        SELECT "user_pseudo_id", "event_name"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180906
        UNION ALL
        SELECT "user_pseudo_id", "event_name"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180907
    )
    WHERE "event_name" = 'first_open'
),
all_events AS (
    SELECT "user_pseudo_id", "event_date"
    FROM (
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180908
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180909
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180910
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180911
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180912
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180913
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180914
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180915
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180916
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180917
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180918
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180919
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180920
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180921
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180922
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180923
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180924
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180925
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180926
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180927
        UNION ALL
        SELECT "user_pseudo_id", "event_date"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180928
    )
    WHERE "user_pseudo_id" IN (SELECT "user_pseudo_id" FROM cohort_users)
),
week_events AS (
    SELECT
        "user_pseudo_id",
        CASE
            WHEN "event_date" BETWEEN '20180908' AND '20180914' THEN '1'
            WHEN "event_date" BETWEEN '20180915' AND '20180921' THEN '2'
            WHEN "event_date" BETWEEN '20180922' AND '20180928' THEN '3'
        END AS "Week"
    FROM all_events
),
retention AS (
    SELECT "Week", COUNT(DISTINCT "user_pseudo_id") AS "retained_users"
    FROM week_events
    WHERE "Week" IS NOT NULL
    GROUP BY "Week"
),
cohort_size AS (
    SELECT COUNT(*) AS "total_users" FROM cohort_users
)
SELECT
    "Week",
    ROUND(("retained_users" / "total_users") * 100, 4) AS "Retention_Rate"
FROM retention, cohort_size
ORDER BY "Week";
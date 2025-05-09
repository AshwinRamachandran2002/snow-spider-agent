WITH
    all_events AS (
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180801
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180802
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180803
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180804
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180805
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180806
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180807
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180808
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180809
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180810
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180811
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180812
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180813
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180814
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180815
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180816
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180817
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180818
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180819
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180820
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180821
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180822
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180823
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180824
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180825
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180826
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180827
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180828
        UNION ALL
        SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282.EVENTS_20180829
    ),
    initial_users AS (
        SELECT
            "user_pseudo_id",
            MIN("user_first_touch_timestamp") AS "first_touch_ts"
        FROM all_events
        GROUP BY "user_pseudo_id"
        HAVING TO_DATE(TO_TIMESTAMP(MIN("user_first_touch_timestamp") / 1000000)) BETWEEN '2018-08-01' AND '2018-08-15'
    ),
    user_events AS (
        SELECT
            e."event_name",
            e."user_pseudo_id",
            e."event_timestamp",
            u."first_touch_ts",
            FLOOR( ("event_timestamp" - u."first_touch_ts") / (1000000 * 60 * 60 * 24) ) AS "days_since_first_touch"
        FROM all_events e
        JOIN initial_users u ON e."user_pseudo_id" = u."user_pseudo_id"
        WHERE e."event_name" LIKE '%_quickplay%'
    ),
    labeled_events AS (
        SELECT
            "event_name",
            "user_pseudo_id",
            "days_since_first_touch",
            CASE
                WHEN "days_since_first_touch" BETWEEN 0 AND 6 THEN 1
                WHEN "days_since_first_touch" BETWEEN 7 AND 13 THEN 2
                ELSE NULL
            END AS "week_number"
        FROM user_events
    ),
    week1_event_users AS (
        SELECT DISTINCT
            "event_name",
            "user_pseudo_id"
        FROM labeled_events
        WHERE "week_number" = 1
    ),
    week2_event_users AS (
        SELECT DISTINCT
            "event_name",
            "user_pseudo_id"
        FROM labeled_events
        WHERE "week_number" = 2
    ),
    retention_calculation AS (
        SELECT
            w1."event_name",
            COUNT(DISTINCT w1."user_pseudo_id") AS "week1_users",
            COUNT(DISTINCT w2."user_pseudo_id") AS "week2_users"
        FROM week1_event_users w1
        LEFT JOIN week2_event_users w2
            ON w1."event_name" = w2."event_name"
            AND w1."user_pseudo_id" = w2."user_pseudo_id"
        GROUP BY w1."event_name"
    ),
    retention_rate AS (
        SELECT
            "event_name" AS "Event_Type",
            ROUND( ("week2_users" * 100.0) / NULLIF("week1_users", 0), 4) AS "Retention_Rate_Week2"
        FROM retention_calculation
    )
SELECT
    "Event_Type",
    "Retention_Rate_Week2"
FROM retention_rate
ORDER BY "Retention_Rate_Week2" ASC NULLS LAST
LIMIT 1;
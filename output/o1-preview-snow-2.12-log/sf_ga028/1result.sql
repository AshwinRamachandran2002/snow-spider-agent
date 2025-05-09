WITH new_users AS (
    SELECT DISTINCT "user_pseudo_id"
    FROM (
        SELECT "user_pseudo_id", "user_first_touch_timestamp"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180702"
        WHERE "user_first_touch_timestamp" >= 1530489600000000 AND "user_first_touch_timestamp" < 1531094400000000
        UNION ALL
        SELECT "user_pseudo_id", "user_first_touch_timestamp"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180703"
        WHERE "user_first_touch_timestamp" >= 1530489600000000 AND "user_first_touch_timestamp" < 1531094400000000
        UNION ALL
        SELECT "user_pseudo_id", "user_first_touch_timestamp"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180704"
        WHERE "user_first_touch_timestamp" >= 1530489600000000 AND "user_first_touch_timestamp" < 1531094400000000
        UNION ALL
        SELECT "user_pseudo_id", "user_first_touch_timestamp"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180705"
        WHERE "user_first_touch_timestamp" >= 1530489600000000 AND "user_first_touch_timestamp" < 1531094400000000
        UNION ALL
        SELECT "user_pseudo_id", "user_first_touch_timestamp"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180706"
        WHERE "user_first_touch_timestamp" >= 1530489600000000 AND "user_first_touch_timestamp" < 1531094400000000
        UNION ALL
        SELECT "user_pseudo_id", "user_first_touch_timestamp"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180707"
        WHERE "user_first_touch_timestamp" >= 1530489600000000 AND "user_first_touch_timestamp" < 1531094400000000
        UNION ALL
        SELECT "user_pseudo_id", "user_first_touch_timestamp"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180708"
        WHERE "user_first_touch_timestamp" >= 1530489600000000 AND "user_first_touch_timestamp" < 1531094400000000
    )
),
events AS (
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180702"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180703"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180704"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180705"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180706"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180707"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180708"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180709"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180710"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180711"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180712"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180713"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180714"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180715"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180716"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180717"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180718"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180719"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180720"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180721"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180722"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180723"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180724"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180725"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180726"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180727"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180728"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180729"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180730"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180731"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180801"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180802"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180803"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180804"
    UNION ALL
    SELECT "user_pseudo_id", "event_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180805"
),
user_events AS (
    SELECT
        e."user_pseudo_id",
        FLOOR( ("event_timestamp" - 1530489600000000) / 604800000000 ) AS week_number
    FROM events e
    INNER JOIN new_users nu ON e."user_pseudo_id" = nu."user_pseudo_id"
    WHERE e."event_timestamp" >= 1530489600000000 AND e."event_timestamp" < 1533513600000000
)
SELECT
    week_number AS "Week",
    CASE WHEN week_number = 0 THEN (SELECT COUNT(*) FROM new_users) ELSE NULL END AS "Total_New_Users",
    COUNT(DISTINCT "user_pseudo_id") AS "Retained_Users"
FROM user_events
GROUP BY week_number
ORDER BY week_number;
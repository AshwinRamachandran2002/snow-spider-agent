WITH event_data AS (
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180702"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180703"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180704"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180705"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180706"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180707"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180708"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180709"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180710"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180711"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180712"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180713"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180714"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180715"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180716"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180717"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180718"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180719"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180720"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180721"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180722"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180723"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180724"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180725"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180726"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180727"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180728"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180729"
    UNION ALL
    SELECT "event_date", "event_name", "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180730"
),
initial_events AS (
    SELECT
        "user_pseudo_id",
        SPLIT_PART("event_name", '_quickplay', 1) AS "quickplay_event_type",
        MIN("event_timestamp") AS "initial_event_timestamp"
    FROM event_data
    WHERE "event_name" LIKE '%quickplay%'
      AND "event_date" BETWEEN '20180702' AND '20180716'
    GROUP BY "user_pseudo_id", SPLIT_PART("event_name", '_quickplay', 1)
),
retention_events AS (
    SELECT DISTINCT
        ie."user_pseudo_id",
        ie."quickplay_event_type"
    FROM initial_events ie
    INNER JOIN event_data ed ON ie."user_pseudo_id" = ed."user_pseudo_id"
    WHERE ed."event_name" LIKE '%quickplay%'
      AND SPLIT_PART(ed."event_name", '_quickplay', 1) = ie."quickplay_event_type"
      AND ed."event_timestamp" >= ie."initial_event_timestamp" + (14 * 86400000000)
      AND ed."event_timestamp" < ie."initial_event_timestamp" + (21 * 86400000000)
)
SELECT
    ie."quickplay_event_type" AS "Quickplay_Event_Type",
    ROUND((COUNT(DISTINCT re."user_pseudo_id") * 100.0) / COUNT(DISTINCT ie."user_pseudo_id"), 4) AS "Retention_Rate"
FROM initial_events ie
LEFT JOIN retention_events re
    ON ie."user_pseudo_id" = re."user_pseudo_id"
   AND ie."quickplay_event_type" = re."quickplay_event_type"
GROUP BY ie."quickplay_event_type"
ORDER BY ie."quickplay_event_type";
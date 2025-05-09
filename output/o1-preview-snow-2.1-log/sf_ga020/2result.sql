WITH initial_events AS (
    SELECT
        "user_pseudo_id",
        "event_name",
        DATE(TO_TIMESTAMP_LTZ("user_first_touch_timestamp" / 1e6)) AS "first_engagement_date",
        DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1e6)) AS "event_date"
    FROM (
        SELECT "user_pseudo_id", "event_name", "user_first_touch_timestamp", "event_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180801"
        UNION ALL SELECT "user_pseudo_id", "event_name", "user_first_touch_timestamp", "event_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180802"
        UNION ALL SELECT "user_pseudo_id", "event_name", "user_first_touch_timestamp", "event_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180803"
        UNION ALL SELECT "user_pseudo_id", "event_name", "user_first_touch_timestamp", "event_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180804"
        UNION ALL SELECT "user_pseudo_id", "event_name", "user_first_touch_timestamp", "event_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180805"
        UNION ALL SELECT "user_pseudo_id", "event_name", "user_first_touch_timestamp", "event_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180806"
        UNION ALL SELECT "user_pseudo_id", "event_name", "user_first_touch_timestamp", "event_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180807"
        UNION ALL SELECT "user_pseudo_id", "event_name", "user_first_touch_timestamp", "event_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808"
        UNION ALL SELECT "user_pseudo_id", "event_name", "user_first_touch_timestamp", "event_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809"
        UNION ALL SELECT "user_pseudo_id", "event_name", "user_first_touch_timestamp", "event_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810"
        UNION ALL SELECT "user_pseudo_id", "event_name", "user_first_touch_timestamp", "event_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811"
        UNION ALL SELECT "user_pseudo_id", "event_name", "user_first_touch_timestamp", "event_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812"
        UNION ALL SELECT "user_pseudo_id", "event_name", "user_first_touch_timestamp", "event_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813"
        UNION ALL SELECT "user_pseudo_id", "event_name", "user_first_touch_timestamp", "event_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814"
        UNION ALL SELECT "user_pseudo_id", "event_name", "user_first_touch_timestamp", "event_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
    ) AS t
    WHERE
        DATE(TO_TIMESTAMP_LTZ(t."user_first_touch_timestamp" / 1e6)) BETWEEN '2018-08-01' AND '2018-08-15'
        AND t."event_name" IN (
            'level_complete_quickplay',
            'level_start_quickplay',
            'level_end_quickplay',
            'level_fail_quickplay',
            'level_retry_quickplay',
            'level_reset_quickplay'
        )
        AND DATE(TO_TIMESTAMP_LTZ(t."event_timestamp" / 1e6)) = DATE(TO_TIMESTAMP_LTZ(t."user_first_touch_timestamp" / 1e6))
),
retention_events AS (
    SELECT
        "user_pseudo_id",
        DATE(TO_TIMESTAMP_LTZ("event_timestamp" / 1e6)) AS "event_date",
        "user_first_touch_timestamp"
    FROM (
        SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180808"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180809"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180810"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180811"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180812"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180813"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180814"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180815"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180816"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180817"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180818"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180819"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180820"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180821"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180822"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180823"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180824"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180825"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180826"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180827"
        UNION ALL SELECT "user_pseudo_id", "event_timestamp", "user_first_touch_timestamp"
        FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180828"
    ) AS t
    WHERE t."user_pseudo_id" IN (SELECT DISTINCT "user_pseudo_id" FROM initial_events)
),
user_retention AS (
    SELECT
        ie."user_pseudo_id",
        ie."event_name",
        MIN(DATEDIFF('DAY', ie."first_engagement_date", re."event_date")) AS "days_since_engagement"
    FROM initial_events ie
    LEFT JOIN retention_events re
        ON ie."user_pseudo_id" = re."user_pseudo_id"
    GROUP BY ie."user_pseudo_id", ie."event_name"
)
SELECT
    "event_name" AS "Event_Type",
    ROUND((COUNT(DISTINCT CASE WHEN "days_since_engagement" BETWEEN 7 AND 13 THEN ie."user_pseudo_id" END) * 100.0)
          / COUNT(DISTINCT ie."user_pseudo_id"), 4) AS "Retention_Rate_Week2"
FROM user_retention ie
GROUP BY "event_name"
ORDER BY "Retention_Rate_Week2" ASC NULLS LAST
LIMIT 1;
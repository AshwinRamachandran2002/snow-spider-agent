WITH initial_engagements AS (
    SELECT
        t."user_pseudo_id",
        MIN(t."event_timestamp") AS initial_engagement_ts,
        f.value:"value":"string_value"::STRING AS "quickplay_event_type"
    FROM (
        SELECT "user_pseudo_id", "event_timestamp", "event_name", "event_params"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180801"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name", "event_params"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180802"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name", "event_params"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180803"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name", "event_params"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180804"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name", "event_params"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180805"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name", "event_params"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180806"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name", "event_params"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180807"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name", "event_params"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180808"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name", "event_params"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180809"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name", "event_params"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180810"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name", "event_params"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180811"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name", "event_params"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180812"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name", "event_params"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180813"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name", "event_params"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180814"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name", "event_params"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180815"
    ) t,
    LATERAL FLATTEN(input => t."event_params") f
    WHERE t."event_name" LIKE '%quickplay%'
      AND f.value:"key"::STRING = 'board'
    GROUP BY t."user_pseudo_id", f.value:"value":"string_value"
),
second_week_sessions AS (
    SELECT
        t."user_pseudo_id",
        t."event_timestamp"
    FROM (
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180808"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180809"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180810"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180811"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180812"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180813"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180814"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180815"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180816"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180817"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180818"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180819"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180820"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180821"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180822"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180823"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180824"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180825"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180826"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180827"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180828"
        UNION ALL
        SELECT "user_pseudo_id", "event_timestamp", "event_name"
        FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180829"
    ) t
    WHERE t."event_name" = 'session_start'
)
SELECT
    ie."quickplay_event_type",
    ROUND(
        (COUNT(DISTINCT s."user_pseudo_id") / COUNT(DISTINCT ie."user_pseudo_id")) * 100, 4
    ) AS "user_retention_rate"
FROM initial_engagements ie
LEFT JOIN second_week_sessions s ON
    ie."user_pseudo_id" = s."user_pseudo_id" AND
    s."event_timestamp" >= ie.initial_engagement_ts + (7 * 24 * 60 * 60 * 1000000) AND
    s."event_timestamp" < ie.initial_engagement_ts + (14 * 24 * 60 * 60 * 1000000)
GROUP BY ie."quickplay_event_type"
ORDER BY "user_retention_rate" ASC
LIMIT 1;
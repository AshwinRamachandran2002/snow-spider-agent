WITH event_data AS (
    SELECT
        t."USER_PSEUDO_ID",
        t."EVENT_TIMESTAMP",
        t."EVENT_NAME",
        MAX(CASE WHEN f.value:"key"::STRING = 'page_title' THEN LOWER(f.value:"value":"string_value"::STRING) END) AS "page_title",
        MAX(CASE WHEN f.value:"key"::STRING = 'ga_session_id' THEN f.value:"value":"int_value"::INTEGER END) AS "ga_session_id"
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" t,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") f
    GROUP BY t."USER_PSEUDO_ID", t."EVENT_TIMESTAMP", t."EVENT_NAME"
),
session_events AS (
    SELECT
        "USER_PSEUDO_ID",
        "ga_session_id",
        "EVENT_TIMESTAMP",
        "page_title",
        ROW_NUMBER() OVER (PARTITION BY "USER_PSEUDO_ID", "ga_session_id" ORDER BY "EVENT_TIMESTAMP") AS event_order
    FROM event_data
    WHERE "ga_session_id" IS NOT NULL AND "page_title" IS NOT NULL
),
sessions_landed_home AS (
    SELECT DISTINCT
        s."USER_PSEUDO_ID",
        s."ga_session_id"
    FROM session_events s
    WHERE s.event_order = 1 AND s."page_title" = 'home'
),
sessions_converted AS (
    SELECT DISTINCT
        lh."USER_PSEUDO_ID",
        lh."ga_session_id"
    FROM sessions_landed_home lh
    JOIN session_events se ON lh."USER_PSEUDO_ID" = se."USER_PSEUDO_ID" AND lh."ga_session_id" = se."ga_session_id"
    WHERE se."page_title" = 'checkout confirmation'
)
SELECT
    ROUND( ( (SELECT COUNT(*) FROM sessions_converted) * 100.0 ) / (SELECT COUNT(*) FROM sessions_landed_home), 4) AS "Session_conversion_rate"
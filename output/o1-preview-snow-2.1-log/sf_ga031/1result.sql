WITH home_sessions AS (
    SELECT DISTINCT f2.value:"value":"int_value"::STRING AS "ga_session_id"
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" t,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") f1,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") f2
    WHERE f1.value:"key" = 'page_title'
      AND f1.value:"value":"string_value"::STRING = 'Home'
      AND f2.value:"key" = 'ga_session_id'
),
checkout_sessions AS (
    SELECT DISTINCT f2.value:"value":"int_value"::STRING AS "ga_session_id"
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" t,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") f1,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") f2
    WHERE f1.value:"key" = 'page_title'
      AND f1.value:"value":"string_value"::STRING = 'Checkout Confirmation'
      AND f2.value:"key" = 'ga_session_id'
),
sessions_with_both AS (
    SELECT hs."ga_session_id"
    FROM home_sessions hs
    INNER JOIN checkout_sessions cs ON hs."ga_session_id" = cs."ga_session_id"
),
counts AS (
    SELECT
        (SELECT COUNT(DISTINCT "ga_session_id") FROM home_sessions) AS total_home_sessions,
        (SELECT COUNT(DISTINCT "ga_session_id") FROM sessions_with_both) AS total_sessions_with_both
)
SELECT ROUND(
    counts.total_sessions_with_both * 100.0 / NULLIF(counts.total_home_sessions, 0),
    4
) AS "Session_conversion_rate"
FROM counts;
WITH event_params AS (
    SELECT
        t."EVENT_TIMESTAMP",
        t."USER_PSEUDO_ID",
        t."EVENT_NAME",
        MAX(CASE WHEN f.VALUE:"key"::STRING = 'ga_session_id' THEN f.VALUE:"value":"int_value"::NUMBER END) AS "SESSION_ID",
        MAX(CASE WHEN f.VALUE:"key"::STRING = 'page_title' THEN f.VALUE:"value":"string_value"::STRING END) AS "PAGE_TITLE"
    FROM
        "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" t,
        LATERAL FLATTEN(input => t."EVENT_PARAMS") f
    WHERE f.VALUE:"key"::STRING IN ('ga_session_id', 'page_title')
    GROUP BY t."EVENT_TIMESTAMP", t."USER_PSEUDO_ID", t."EVENT_NAME"
),

sessions_with_home AS (
    SELECT DISTINCT "SESSION_ID"
    FROM event_params
    WHERE "PAGE_TITLE" = 'Home' AND "SESSION_ID" IS NOT NULL
),

sessions_with_checkout_confirmation AS (
    SELECT DISTINCT "SESSION_ID"
    FROM event_params
    WHERE "PAGE_TITLE" = 'Checkout Confirmation' AND "SESSION_ID" IS NOT NULL
),

sessions_with_home_and_checkout AS (
    SELECT "SESSION_ID"
    FROM sessions_with_home
    WHERE "SESSION_ID" IN (SELECT "SESSION_ID" FROM sessions_with_checkout_confirmation)
)

SELECT ROUND(
    100.0 * COUNT(DISTINCT "SESSION_ID") / (SELECT COUNT(*) FROM sessions_with_home),
    4
) AS "Session_conversion_rate"
FROM sessions_with_home_and_checkout;
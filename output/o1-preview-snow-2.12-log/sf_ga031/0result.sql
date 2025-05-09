WITH home_sessions AS (
    SELECT DISTINCT
        ep_sess.VALUE:"value":"int_value"::NUMBER AS "ga_session_id"
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" AS e,
        LATERAL FLATTEN(INPUT => e."EVENT_PARAMS") AS ep_title,
        LATERAL FLATTEN(INPUT => e."EVENT_PARAMS") AS ep_sess
    WHERE e."EVENT_NAME" = 'page_view'
        AND ep_title.VALUE:"key"::STRING = 'page_title'
        AND ep_title.VALUE:"value":"string_value"::STRING = 'Home'
        AND ep_sess.VALUE:"key"::STRING = 'ga_session_id'
),
sessions_with_both AS (
    SELECT "ga_session_id"
    FROM (
        SELECT DISTINCT
            ep_sess.VALUE:"value":"int_value"::NUMBER AS "ga_session_id",
            ep_title.VALUE:"value":"string_value"::STRING AS "page_title"
        FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" AS e,
            LATERAL FLATTEN(INPUT => e."EVENT_PARAMS") AS ep_title,
            LATERAL FLATTEN(INPUT => e."EVENT_PARAMS") AS ep_sess
        WHERE e."EVENT_NAME" = 'page_view'
            AND ep_title.VALUE:"key"::STRING = 'page_title'
            AND ep_sess.VALUE:"key"::STRING = 'ga_session_id'
            AND ep_sess.VALUE:"value":"int_value"::NUMBER IN (SELECT "ga_session_id" FROM home_sessions)
    ) AS t
    WHERE "page_title" IN ('Home', 'Checkout Confirmation')
    GROUP BY "ga_session_id"
    HAVING COUNT(DISTINCT "page_title") = 2
)
SELECT
    ROUND((COUNT(DISTINCT sessions_with_both."ga_session_id") * 100.0) / COUNT(DISTINCT home_sessions."ga_session_id"), 6) AS "Conversion_rate"
FROM home_sessions
LEFT JOIN sessions_with_both ON home_sessions."ga_session_id" = sessions_with_both."ga_session_id";
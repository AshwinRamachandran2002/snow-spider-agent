/* Conversion rate on 02-Jan-2021 based only on page_view events           */
/* – Denominator : sessions that viewed the Home page                      */
/* – Numerator   : the same sessions that ALSO viewed a confirmation page  */

WITH pv AS (   /* one row per page_view event with its session id & title */
    SELECT
        e."USER_PSEUDO_ID",
        e."EVENT_TIMESTAMP",
        MAX(
            CASE
                WHEN f.value:"key"::STRING = 'ga_session_id'
                THEN f.value:"int_value"::NUMBER
            END
        ) AS "SESSION_ID",
        MAX(
            CASE
                WHEN f.value:"key"::STRING = 'page_title'
                THEN f.value:"string_value"::STRING
            END
        ) AS "PAGE_TITLE"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"       e
         , LATERAL FLATTEN ( INPUT => e."EVENT_PARAMS" )              f
    WHERE e."EVENT_NAME" = 'page_view'
    GROUP BY e."USER_PSEUDO_ID", e."EVENT_TIMESTAMP"
),
sessions AS (  /* flag each (user,session) for Home / Confirmation views */
    SELECT
        "USER_PSEUDO_ID",
        "SESSION_ID",
        MAX( CASE WHEN "PAGE_TITLE" = 'Home'                          THEN 1 ELSE 0 END ) AS "HAS_HOME",
        MAX( CASE WHEN UPPER("PAGE_TITLE") LIKE '%CONFIRMATION%'      THEN 1 ELSE 0 END ) AS "HAS_CONFIRMATION"
    FROM pv
    WHERE "SESSION_ID" IS NOT NULL
    GROUP BY "USER_PSEUDO_ID", "SESSION_ID"
)
SELECT
    SUM( CASE WHEN "HAS_HOME" = 1                          THEN 1 ELSE 0 END ) AS "SESSIONS_LANDED_HOME",
    SUM( CASE WHEN "HAS_HOME" = 1 AND "HAS_CONFIRMATION"=1 THEN 1 ELSE 0 END ) AS "SESSIONS_WITH_HOME_AND_CONFIRMATION",
    ROUND(
        100.0 * SUM( CASE WHEN "HAS_HOME" = 1 AND "HAS_CONFIRMATION" = 1 THEN 1 ELSE 0 END )
        / NULLIF( SUM( CASE WHEN "HAS_HOME" = 1 THEN 1 ELSE 0 END ), 0 ),
        4
    ) AS "CONVERSION_RATE_PERCENT"
FROM sessions;
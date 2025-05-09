/* -----------------------------------------------------------
   Conversion rate on 2021-01-02
   – “converted” session  = reached Home AND Checkout-confirmation
   – denominator          = sessions that reached Home
   – only page_view events are considered
-------------------------------------------------------------*/
WITH page_views AS (      -- extract needed fields from page_view rows
    SELECT
        t."USER_PSEUDO_ID",
        MAX(CASE WHEN f.value:"key"::STRING = 'ga_session_id'
                 THEN f.value:"int_value"::NUMBER END)                         AS "ga_session_id",
        MAX(CASE WHEN f.value:"key"::STRING = 'page_location'
                 THEN f.value:"string_value"::STRING END)                      AS "page_location",
        MAX(CASE WHEN f.value:"key"::STRING = 'page_title'
                 THEN f.value:"string_value"::STRING END)                      AS "page_title"
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102"  t,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") f
    WHERE t."EVENT_NAME" = 'page_view'
    GROUP BY t."USER_PSEUDO_ID",             -- one record per event
             t."EVENT_TIMESTAMP"
),
session_flags AS (        -- flag if a session saw Home / Checkout pages
    SELECT
        "USER_PSEUDO_ID",
        "ga_session_id",
        MAX(
            CASE
                WHEN "page_location" = 'https://shop.googlemerchandisestore.com/'
                     OR LOWER("page_title") = 'home'
                THEN 1 ELSE 0 END
        ) AS has_home,
        MAX(
            CASE
                WHEN LOWER("page_location") LIKE '%checkout%'
                     OR LOWER("page_title")  LIKE '%checkout%'
                     OR LOWER("page_title")  LIKE '%confirmation%'
                THEN 1 ELSE 0 END
        ) AS has_checkout
    FROM page_views
    GROUP BY "USER_PSEUDO_ID", "ga_session_id"
),
summary AS (              -- count sessions
    SELECT
        COUNT_IF(has_home = 1)                              AS sessions_home,
        COUNT_IF(has_home = 1 AND has_checkout = 1)         AS sessions_conversion
    FROM session_flags
)
SELECT
    sessions_conversion,
    sessions_home,
    ROUND(100.0 * sessions_conversion / NULLIF(sessions_home,0), 4)
        AS conversion_rate_percent
FROM summary;
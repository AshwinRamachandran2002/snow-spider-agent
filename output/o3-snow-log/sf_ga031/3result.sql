/*  Conversion rate for sessions on 2021-01-02 that
    reached both the Home page and a Checkout-confirmation page
    (based solely on 'page_view' events)                                       */

WITH page_views AS (      -- unpack page_location + ga_session_id for every page_view
    SELECT
        ses.value:"value":"int_value"::NUMBER      AS "GA_SESSION_ID",
        url.value:"value":"string_value"::STRING   AS "PAGE_LOCATION"
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" t,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") url,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") ses
    WHERE t."EVENT_NAME" = 'page_view'
      AND url.value:"key"::STRING = 'page_location'
      AND ses.value:"key"::STRING = 'ga_session_id'
),

home_sessions AS (        -- sessions that hit the site Home page
    SELECT DISTINCT "GA_SESSION_ID"
    FROM page_views
    WHERE "PAGE_LOCATION" = 'https://shop.googlemerchandisestore.com/'
),

checkout_sessions AS (    -- sessions that hit a likely confirmation page
    SELECT DISTINCT "GA_SESSION_ID"
    FROM page_views
    WHERE LOWER("PAGE_LOCATION") LIKE '%confirm%'
       OR LOWER("PAGE_LOCATION") LIKE '%receipt%'
       OR LOWER("PAGE_LOCATION") LIKE '%order%'
       OR LOWER("PAGE_LOCATION") LIKE '%thank%'
)

SELECT
    (SELECT COUNT(*) FROM home_sessions)                                              AS "HOME_SESSIONS",
    (SELECT COUNT(*) FROM checkout_sessions)                                          AS "CHECKOUT_SESSIONS",
    (SELECT COUNT(*) FROM home_sessions h JOIN checkout_sessions c USING("GA_SESSION_ID"))
                                                                                      AS "HOME_AND_CHECKOUT_SESSIONS",
    ROUND(
           (SELECT COUNT(*) FROM home_sessions h JOIN checkout_sessions c USING("GA_SESSION_ID"))
           / NULLIF((SELECT COUNT(*) FROM home_sessions), 0)::FLOAT * 100
         , 4)                                                                         AS "CONVERSION_RATE_PERCENT";
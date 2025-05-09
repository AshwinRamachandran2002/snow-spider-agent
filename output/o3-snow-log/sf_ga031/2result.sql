WITH page_views AS (
    /* 1. Pull the session id and URL for every page_view event on 2-Jan-2021 */
    SELECT
        ses.value:"value":"int_value"::NUMBER  AS "ga_session_id",
        loc.value:"value":"string_value"::STRING AS "page_location"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102" t,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") loc,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") ses
    WHERE t."EVENT_NAME" = 'page_view'
      AND loc.value:"key"::STRING  = 'page_location'
      AND ses.value:"key"::STRING  = 'ga_session_id'
),
/* 2. Sessions that hit the Home page                          */
home_sessions AS (
    SELECT DISTINCT "ga_session_id"
    FROM page_views
    WHERE "page_location" IN (
            'https://shop.googlemerchandisestore.com',
            'https://shop.googlemerchandisestore.com/'
          )
),
/* 3. Sessions that reached a Checkout-Confirmation type page   */
confirm_sessions AS (
    SELECT DISTINCT "ga_session_id"
    FROM page_views
    WHERE "page_location" ILIKE '%checkout%'      /* checkout flow */
      AND (  "page_location" ILIKE '%confirm%'    /* confirmation keywords */
          OR "page_location" ILIKE '%thank%' 
          OR "page_location" ILIKE '%order%' )
),
/* 4. Sessions that saw BOTH Home and Confirmation              */
converting_sessions AS (
    SELECT h."ga_session_id"
    FROM home_sessions h
    JOIN confirm_sessions c USING ("ga_session_id")
)
/* 5. Calculate the conversion rate (to four decimals)          */
SELECT
    ROUND(
        (COUNT(DISTINCT cs."ga_session_id") * 100.0)
        / NULLIF(COUNT(DISTINCT hs."ga_session_id"), 0)
    , 4
    ) AS "conversion_rate_percent"
FROM home_sessions hs
LEFT JOIN converting_sessions cs USING ("ga_session_id");
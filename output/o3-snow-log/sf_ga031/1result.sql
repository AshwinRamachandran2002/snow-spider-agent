/*  Conversion rate on 2-Jan-2021: sessions that hit both the Home page
    and a Checkout–confirmation page ÷ sessions that hit the Home page          */

WITH pageviews AS (      -- pull session id and URL from page_view rows
    SELECT
        t."USER_PSEUDO_ID",
        id.value:"value":"int_value"::NUMBER     AS "ga_session_id",
        loc.value:"value":"string_value"::STRING AS "page_location"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"  t
         ,LATERAL FLATTEN(input => t."EVENT_PARAMS") id
         ,LATERAL FLATTEN(input => t."EVENT_PARAMS") loc
    WHERE t."EVENT_NAME" = 'page_view'
      AND id.value:"key"::STRING  = 'ga_session_id'
      AND loc.value:"key"::STRING = 'page_location'
),

session_flags AS (       -- flag whether each session saw Home and/or Checkout-confirm
    SELECT
        "USER_PSEUDO_ID",
        "ga_session_id",
        MAX( CASE
                WHEN LOWER("page_location") IN
                     ('https://shop.googlemerchandisestore.com/',
                      'https://shop.googlemerchandisestore.com')
                THEN 1 ELSE 0 END )                                            AS reached_home,
        MAX( CASE
                WHEN "page_location" ILIKE '%checkout%'
                   OR "page_location" ILIKE '%confirm%'
                   OR "page_location" ILIKE '%thank%'
                   OR "page_location" ILIKE '%order%'
                THEN 1 ELSE 0 END )                                            AS reached_checkout_confirm
    FROM pageviews
    GROUP BY "USER_PSEUDO_ID", "ga_session_id"
),

totals AS (               -- count the two session groups
    SELECT
        SUM( CASE WHEN reached_home = 1 THEN 1 ELSE 0 END )           AS sessions_with_home,
        SUM( CASE WHEN reached_home = 1
                   AND reached_checkout_confirm = 1
                   THEN 1 ELSE 0 END )                                AS sessions_with_home_and_confirm
    FROM session_flags
)

SELECT
    sessions_with_home,
    sessions_with_home_and_confirm,
    ROUND( sessions_with_home_and_confirm * 100.0
           / NULLIF(sessions_with_home,0), 2)  AS conversion_rate_pct
FROM totals;
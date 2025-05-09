/* Conversion-rate for 2-Jan-2021 sessions that
   (a) landed on a “Home” page and
   (b) also hit a Checkout-Confirmation page,
   using only page_view events                                  */

WITH page_views AS (   -- pull session id + page title for every page_view
    SELECT
        t."USER_PSEUDO_ID",
        f_id.value:"value":"int_value"::NUMBER      AS "GA_SESSION_ID",
        f_title.value:"value":"string_value"::STRING AS "PAGE_TITLE"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"   t
         ,LATERAL FLATTEN(input => t."EVENT_PARAMS")              f_id
         ,LATERAL FLATTEN(input => t."EVENT_PARAMS")              f_title
    WHERE t."EVENT_NAME"              = 'page_view'
      AND f_id.value:"key"::STRING    = 'ga_session_id'
      AND f_title.value:"key"::STRING = 'page_title'
),

home_sessions AS (      -- sessions that saw any Home page
    SELECT DISTINCT "GA_SESSION_ID", "USER_PSEUDO_ID"
    FROM   page_views
    WHERE  "PAGE_TITLE" ILIKE '%home%'
),

checkout_sessions AS (  -- sessions that saw checkout-confirmation
    SELECT DISTINCT "GA_SESSION_ID", "USER_PSEUDO_ID"
    FROM   page_views
    WHERE  "PAGE_TITLE" ILIKE '%checkout%confirm%'
),

converting_sessions AS ( -- sessions that saw BOTH Home and Confirmation
    SELECT  h."GA_SESSION_ID", h."USER_PSEUDO_ID"
    FROM    home_sessions     h
    JOIN    checkout_sessions c
           ON h."GA_SESSION_ID"  = c."GA_SESSION_ID"
          AND h."USER_PSEUDO_ID" = c."USER_PSEUDO_ID"
)

SELECT
    COUNT(DISTINCT c."GA_SESSION_ID")                                  AS "CONVERTING_SESSIONS",
    COUNT(DISTINCT h."GA_SESSION_ID")                                  AS "HOME_SESSIONS",
    ROUND(
        100.0 * COUNT(DISTINCT c."GA_SESSION_ID")
               / NULLIF(COUNT(DISTINCT h."GA_SESSION_ID"),0)
    ,4)                                                                AS "CONVERSION_RATE_PCT"
FROM   home_sessions h
LEFT   JOIN converting_sessions c
       ON h."GA_SESSION_ID" = c."GA_SESSION_ID"
      AND h."USER_PSEUDO_ID" = c."USER_PSEUDO_ID";
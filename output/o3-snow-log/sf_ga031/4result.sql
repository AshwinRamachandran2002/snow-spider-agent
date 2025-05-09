/*  Conversion rate for 2-Jan-2021
    (% of sessions that saw BOTH the Home page and the Checkout-Confirmation page
     out of all sessions that saw the Home page), using only page_view events.   */
WITH "BASE" AS (   -- page titles and session ids for every page_view
    SELECT
        s.value:"value":"int_value"::NUMBER   AS "GA_SESSION_ID",
        p.value:"value":"string_value"::STRING AS "PAGE_TITLE"
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" t,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") p,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") s
    WHERE t."EVENT_NAME" = 'page_view'
      AND p.value:"key"::STRING = 'page_title'
      AND s.value:"key"::STRING = 'ga_session_id'
),
"SESSIONS_WITH_HOME" AS (          -- all sessions that hit the Home page
    SELECT DISTINCT "GA_SESSION_ID"
    FROM "BASE"
    WHERE "PAGE_TITLE" ILIKE '%home%'
),
"SESSIONS_WITH_HOME_AND_CONFIRM" AS (   -- sessions that hit both Home & Confirmation
    SELECT "GA_SESSION_ID"
    FROM   "BASE"
    GROUP BY "GA_SESSION_ID"
    HAVING MAX(CASE WHEN "PAGE_TITLE" ILIKE '%home%' THEN 1 ELSE 0 END) = 1
       AND MAX(CASE WHEN "PAGE_TITLE" ILIKE '%checkout%confirmation%' THEN 1 ELSE 0 END) = 1
)
SELECT
    (SELECT COUNT(*) FROM "SESSIONS_WITH_HOME_AND_CONFIRM") * 100.0
    / NULLIF((SELECT COUNT(*) FROM "SESSIONS_WITH_HOME"), 0)  AS "CONVERSION_RATE_PERCENT";
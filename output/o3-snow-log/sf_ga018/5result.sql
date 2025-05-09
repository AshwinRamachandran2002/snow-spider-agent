/*  PLP-to-PDP transition rate for 02-Jan-2021                     */
/*  – page_view events only                                         */
/*  – GA4 sample e-commerce data in Snowflake                       */

WITH page_views AS (           /* 1. every page_view URL + session */
    SELECT
        t."USER_PSEUDO_ID",
        s.value:"value"."int_value"::NUMBER          AS "session_id",
        l.value:"value"."string_value"::STRING       AS "url"
    FROM "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" t
         ,LATERAL FLATTEN(input => t."EVENT_PARAMS") l   /* page_location */
         ,LATERAL FLATTEN(input => t."EVENT_PARAMS") s   /* ga_session_id */
    WHERE t."EVENT_NAME"        = 'page_view'
      AND l.value:"key"::STRING = 'page_location'
      AND s.value:"key"::STRING = 'ga_session_id'
      AND l.value:"value"."string_value" IS NOT NULL
),
classified AS (                /* 2. tag each view as PLP or PDP   */
    SELECT
        "USER_PSEUDO_ID",
        "session_id",
        /* ---------- Product List Page (PLP) ---------- */
        CASE
            WHEN (
                    "url" ILIKE '%/Accessories/%'         OR "url" ILIKE '%/Apparel/%'          OR
                    "url" ILIKE '%/Brands/%'              OR "url" ILIKE '%/Campus%Collection/%'OR
                    "url" ILIKE '%/Drinkware/%'           OR "url" ILIKE '%/Electronics/%'      OR
                    "url" ILIKE '%/Google%Redesign/%'     OR "url" ILIKE '%/Lifestyle/%'        OR
                    "url" ILIKE '%/Nest/%'                OR "url" ILIKE '%/New%2015%Logo/%'    OR
                    "url" ILIKE '%/Notebooks%Journals/%'  OR "url" ILIKE '%/Office/%'           OR
                    "url" ILIKE '%/Shop%by%Brand/%'       OR "url" ILIKE '%/Small%Goods/%'      OR
                    "url" ILIKE '%/Stationery/%'          OR "url" ILIKE '%/Wearables/%'
                 )
                 AND "url" NOT ILIKE '%+%'  THEN 1 ELSE 0 END       AS is_plp,
        /* ---------- Product Detail Page (PDP) ---------- */
        CASE
            WHEN (
                    "url" ILIKE '%/Accessories/%'         OR "url" ILIKE '%/Apparel/%'          OR
                    "url" ILIKE '%/Brands/%'              OR "url" ILIKE '%/Campus%Collection/%'OR
                    "url" ILIKE '%/Drinkware/%'           OR "url" ILIKE '%/Electronics/%'      OR
                    "url" ILIKE '%/Google%Redesign/%'     OR "url" ILIKE '%/Lifestyle/%'        OR
                    "url" ILIKE '%/Nest/%'                OR "url" ILIKE '%/New%2015%Logo/%'    OR
                    "url" ILIKE '%/Notebooks%Journals/%'  OR "url" ILIKE '%/Office/%'           OR
                    "url" ILIKE '%/Shop%by%Brand/%'       OR "url" ILIKE '%/Small%Goods/%'      OR
                    "url" ILIKE '%/Stationery/%'          OR "url" ILIKE '%/Wearables/%'
                 )
                 AND "url" ILIKE '%+%'  THEN 1 ELSE 0 END           AS is_pdp
    FROM page_views
),
session_flags AS (             /* 3. roll up to session level      */
    SELECT
        "session_id",
        MAX(is_plp) AS has_plp,
        MAX(is_pdp) AS has_pdp
    FROM classified
    GROUP BY "session_id"
),
stats AS (                      /* 4. aggregate counts              */
    SELECT
        COUNT_IF(has_plp = 1)                              AS plp_sessions,
        COUNT_IF(has_plp = 1 AND has_pdp = 1)              AS plp_to_pdp_sessions
    FROM session_flags
)
-- 5. final result: raw counts + transition rate %
SELECT
    plp_sessions,
    plp_to_pdp_sessions,
    ROUND(plp_to_pdp_sessions * 100.0 / NULLIF(plp_sessions,0), 2) 
        AS plp_to_pdp_percentage
FROM stats;
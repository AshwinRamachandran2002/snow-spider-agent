/* -----------------------------------------------------------
   PLP → PDP transition rate for 02-Jan-2021 (page_view only)
   ----------------------------------------------------------- */
WITH page_views AS (   -- 1. 1 row per user timestamp holding URL & session
    SELECT
        t."EVENT_TIMESTAMP",
        t."USER_PSEUDO_ID",
        /* grab session & URL out of the JSON array */
        MAX(CASE WHEN f.value:"key"::STRING = 'ga_session_id'
                 THEN f.value:"value":"int_value" END)      AS "session_id",
        MAX(CASE WHEN f.value:"key"::STRING = 'page_location'
                 THEN f.value:"value":"string_value" END)   AS "url"
    FROM  GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"  t,
          LATERAL FLATTEN(input => t."EVENT_PARAMS")              f
    WHERE t."EVENT_NAME" = 'page_view'
    GROUP BY t."EVENT_TIMESTAMP", t."USER_PSEUDO_ID"
),
/* 2. Sessions that include at least one PDP view (URL contains “+”) */
sessions_with_pdp AS (
    SELECT DISTINCT "session_id"
    FROM   page_views
    WHERE  "url" ILIKE '%+%'          -- PDP heuristic
      AND  "session_id" IS NOT NULL
),
/* 3. Total PLP views (URL does NOT contain “+”) */
totals AS (
    SELECT COUNT(*) AS "plp_total"
    FROM   page_views
    WHERE  "url" NOT ILIKE '%+%'      -- PLP heuristic
),
/* 4. PLP views that belong to a session having ≥1 PDP */
converted AS (
    SELECT COUNT(*) AS "plp_to_pdp"
    FROM   page_views
    WHERE  "url" NOT ILIKE '%+%'      -- still a PLP view
      AND  "session_id" IN (SELECT "session_id" FROM sessions_with_pdp)
)
SELECT 
       converted."plp_to_pdp",          -- # PLP views converting to PDP
       totals."plp_total",              -- total PLP views that day
       ROUND(
           100.0 * converted."plp_to_pdp" / NULLIF(totals."plp_total",0),
           2
       ) AS "plp_to_pdp_percent"        -- transition %
FROM   converted
JOIN   totals ON 1=1;
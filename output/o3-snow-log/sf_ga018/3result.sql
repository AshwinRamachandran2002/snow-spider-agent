/* -----------------------------------------------
   PLP-to-PDP transition rate ‑ 02-Jan-2021
   ----------------------------------------------- */
WITH page_views AS (      -- 1) one row per page_view with session-id & URL
  SELECT
        MAX( CASE WHEN f.value:"key"::STRING = 'ga_session_id'
                  THEN f.value:"value":"int_value"::NUMBER END )  AS "session_id",
        MAX( CASE WHEN f.value:"key"::STRING = 'page_location'
                  THEN f.value:"value":"string_value"::STRING END ) AS "url"
  FROM   "GA4"."GA4_OBFUSCATED_SAMPLE_ECOMMERCE"."EVENTS_20210102" t,
         LATERAL FLATTEN( INPUT => t."EVENT_PARAMS" ) f
  WHERE  t."EVENT_NAME" = 'page_view'
  GROUP  BY t."EVENT_TIMESTAMP"
),
sessions AS (             -- 2) flag sessions that contain ≥1 PDP view
  SELECT  "session_id",
          MAX( CASE WHEN "url" ILIKE '%+%' THEN 1 ELSE 0 END ) AS "has_pdp"
  FROM    page_views
  GROUP   BY "session_id"
),
plp AS (                   -- 3) keep only PLP views (+ PDP flag of their session)
  SELECT  pv.*, s."has_pdp"
  FROM    page_views  pv
  JOIN    sessions    s  USING ("session_id")
  WHERE   pv."url" NOT ILIKE '%+%'          -- PLP heuristic: no “+” in URL
)
-- 4) final counts & percentage
SELECT  COUNT(*)                                            AS "TOTAL_PLP_VIEWS",
        COUNT_IF( "has_pdp" = 1 )                           AS "PLP_VIEWS_WITH_PDP_SESSION",
        ROUND( 100 * COUNT_IF( "has_pdp" = 1 )
               / NULLIF( COUNT(*), 0 ), 2 )                 AS "PCT_PLP_TO_PDP"
FROM    plp;
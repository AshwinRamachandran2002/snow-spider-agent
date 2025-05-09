/*  PLP-to-PDP transition rate for 2-Jan-2021  */

WITH all_page_views AS (           -- every page_view with its URL and session id
    SELECT
        t."USER_PSEUDO_ID",
        g.value:"value":"int_value"::NUMBER    AS "ga_session_id",
        t."EVENT_TIMESTAMP",
        p.value:"value":"string_value"::STRING AS "url"
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102" t,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") p,
         LATERAL FLATTEN(input => t."EVENT_PARAMS") g
    WHERE t."EVENT_NAME"        = 'page_view'
      AND p.value:"key"::STRING = 'page_location'
      AND g.value:"key"::STRING = 'ga_session_id'
),

/* classify each page as PLP or PDP according to the refined rules */
classified AS (
    SELECT
        *,
        CASE
            WHEN "url" ILIKE '%+%'                                         -- plus sign
                 AND ( "url" ILIKE '%Accessories%'        OR "url" ILIKE '%Apparel%'
                    OR "url" ILIKE '%Brands%'             OR "url" ILIKE '%Campus%Collection%'
                    OR "url" ILIKE '%Drinkware%'          OR "url" ILIKE '%Electronics%'
                    OR "url" ILIKE '%Google%Redesign%'    OR "url" ILIKE '%Lifestyle%'
                    OR "url" ILIKE '%Nest%'               OR "url" ILIKE '%New%2015%Logo%'
                    OR "url" ILIKE '%Notebooks%Journals%' OR "url" ILIKE '%Office%'
                    OR "url" ILIKE '%Shop%by%Brand%'      OR "url" ILIKE '%Small%Goods%'
                    OR "url" ILIKE '%Stationery%'         OR "url" ILIKE '%Wearables%' )
              THEN 'PDP'
            WHEN "url" NOT ILIKE '%+%'                                    -- no plus sign
                 AND ( "url" ILIKE '%Accessories%'        OR "url" ILIKE '%Apparel%'
                    OR "url" ILIKE '%Brands%'             OR "url" ILIKE '%Campus%Collection%'
                    OR "url" ILIKE '%Drinkware%'          OR "url" ILIKE '%Electronics%'
                    OR "url" ILIKE '%Google%Redesign%'    OR "url" ILIKE '%Lifestyle%'
                    OR "url" ILIKE '%Nest%'               OR "url" ILIKE '%New%2015%Logo%'
                    OR "url" ILIKE '%Notebooks%Journals%' OR "url" ILIKE '%Office%'
                    OR "url" ILIKE '%Shop%by%Brand%'      OR "url" ILIKE '%Small%Goods%'
                    OR "url" ILIKE '%Stationery%'         OR "url" ILIKE '%Wearables%' )
              THEN 'PLP'
        END AS "page_type"
    FROM all_page_views
),

plp AS ( SELECT * FROM classified WHERE "page_type" = 'PLP' ),
pdp AS ( SELECT * FROM classified WHERE "page_type" = 'PDP' ),

/* every PLP that is followed later in the same session by any PDP */
transitions AS (
    SELECT DISTINCT
           plp."USER_PSEUDO_ID",
           plp."ga_session_id",
           plp."EVENT_TIMESTAMP"
    FROM plp
    JOIN pdp
      ON plp."USER_PSEUDO_ID" = pdp."USER_PSEUDO_ID"
     AND plp."ga_session_id"  = pdp."ga_session_id"
     AND pdp."EVENT_TIMESTAMP" > plp."EVENT_TIMESTAMP"
)

SELECT
       COUNT(*)                               AS "plp_with_subsequent_pdp",
       (SELECT COUNT(*) FROM plp)             AS "total_plp_views",
       ROUND(
           CASE WHEN (SELECT COUNT(*) FROM plp) = 0
                THEN 0
                ELSE 100.0 * COUNT(*) / (SELECT COUNT(*) FROM plp)
           END
       , 4)                                   AS "plp_to_pdp_pct"
FROM transitions;
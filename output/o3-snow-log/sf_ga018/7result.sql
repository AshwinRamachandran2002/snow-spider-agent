/*  PLP-to-PDP transition rate for 2021-01-02 (page_view events only)  */
WITH page_views AS (                 -- pull URL, session and timestamp
    SELECT
        gs.value:"value":"int_value"::NUMBER    AS GA_SESSION_ID,
        e."EVENT_TIMESTAMP"                     AS TS,
        ep.value:"value":"string_value"::STRING AS URL
    FROM GA4.GA4_OBFUSCATED_SAMPLE_ECOMMERCE."EVENTS_20210102"  e
         ,LATERAL FLATTEN(input => e."EVENT_PARAMS") ep
         ,LATERAL FLATTEN(input => e."EVENT_PARAMS") gs
    WHERE e."EVENT_NAME" = 'page_view'
      AND ep.value:"key"::STRING = 'page_location'
      AND gs.value:"key"::STRING = 'ga_session_id'
      AND ep.value:"value":"string_value"::STRING IS NOT NULL
),
/* classify each page_view as PLP or PDP */
classified AS (
    SELECT
        GA_SESSION_ID,
        TS,
        URL,
        /* PDP : contains “+” and one of the category names */
        CASE WHEN URL ILIKE '%+%' AND (
                 URL ILIKE '%Accessories%'         OR URL ILIKE '%Apparel%'            OR
                 URL ILIKE '%Brands%'              OR URL ILIKE '%Campus%Collection%'   OR
                 URL ILIKE '%Drinkware%'           OR URL ILIKE '%Electronics%'        OR
                 URL ILIKE '%Google%Redesign%'     OR URL ILIKE '%Lifestyle%'          OR
                 URL ILIKE '%Nest%'                OR URL ILIKE '%New%2015%Logo%'      OR
                 URL ILIKE '%Notebooks%Journals%'  OR URL ILIKE '%Office%'             OR
                 URL ILIKE '%Shop%by%Brand%'       OR URL ILIKE '%Small%Goods%'        OR
                 URL ILIKE '%Stationery%'          OR URL ILIKE '%Wearables%'
             ) THEN 1 ELSE 0 END AS IS_PDP,
        /* PLP : same categories but WITHOUT “+” */
        CASE WHEN URL NOT ILIKE '%+%' AND (
                 URL ILIKE '%Accessories%'         OR URL ILIKE '%Apparel%'            OR
                 URL ILIKE '%Brands%'              OR URL ILIKE '%Campus%Collection%'   OR
                 URL ILIKE '%Drinkware%'           OR URL ILIKE '%Electronics%'        OR
                 URL ILIKE '%Google%Redesign%'     OR URL ILIKE '%Lifestyle%'          OR
                 URL ILIKE '%Nest%'                OR URL ILIKE '%New%2015%Logo%'      OR
                 URL ILIKE '%Notebooks%Journals%'  OR URL ILIKE '%Office%'             OR
                 URL ILIKE '%Shop%by%Brand%'       OR URL ILIKE '%Small%Goods%'        OR
                 URL ILIKE '%Stationery%'          OR URL ILIKE '%Wearables%'
             ) THEN 1 ELSE 0 END AS IS_PLP
    FROM page_views
),
plp_views  AS (SELECT * FROM classified WHERE IS_PLP = 1),
pdp_views  AS (SELECT * FROM classified WHERE IS_PDP = 1),

/* every PLP view that is later followed by any PDP view in the same session */
plp_followed_by_pdp AS (
    SELECT DISTINCT P.GA_SESSION_ID, P.TS
    FROM plp_views P
    WHERE EXISTS (
        SELECT 1
        FROM pdp_views D
        WHERE D.GA_SESSION_ID = P.GA_SESSION_ID
          AND D.TS > P.TS               -- PDP occurs after the PLP
    )
)

/* final counts & percentage */
SELECT
    (SELECT COUNT(*) FROM plp_views)            AS TOTAL_PLP_VIEWS,
    (SELECT COUNT(*) FROM plp_followed_by_pdp)  AS PLP_VIEWS_THEN_PDP,
    ROUND(
        (SELECT COUNT(*) FROM plp_followed_by_pdp) * 100.0
        / NULLIF((SELECT COUNT(*) FROM plp_views), 0),
        2
    )                                           AS PLP_TO_PDP_TRANSITION_PCT;
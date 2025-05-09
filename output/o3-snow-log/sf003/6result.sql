/*  Second–highest ZIP-code population growth (≥25 k pop) for each year 2015-2020  */
WITH pop AS (   -- 5-Year ACS population for all ZCTAs
    SELECT 
        "GEO_ID",
        EXTRACT(YEAR FROM "DATE")          AS "YEAR",
        "VALUE"::FLOAT                     AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'        -- total population, 5-yr estimate
      AND "GEO_ID" LIKE 'zip/%'
      AND EXTRACT(YEAR FROM "DATE") BETWEEN 2014 AND 2020
), 
growth AS (     -- year-over-year growth %
    SELECT 
        c."GEO_ID",
        c."YEAR",
        c."POP"                              AS "POP_CUR",
        p."POP"                              AS "POP_PREV",
        (c."POP" - p."POP") / NULLIF(p."POP",0) * 100  AS "GROWTH_RATE"
    FROM pop  c
    JOIN pop  p
          ON  c."GEO_ID" = p."GEO_ID"
         AND  c."YEAR"   = p."YEAR" + 1          -- previous year
    WHERE c."YEAR" BETWEEN 2015 AND 2020
      AND c."POP" >= 25000                       -- ≥25 k population in current year
), 
zip_state AS (  -- map ZIP ➜ state abbreviation
    SELECT 
        r."RELATED_GEO_ID"                  AS "ZIP_GEO_ID",
        s."ISO_3166_2_CODE"                 AS "STATE_ABBR"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS  r
    JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX          s
      ON r."GEO_ID" = s."GEO_ID"
    WHERE r."LEVEL"            = 'State'
      AND r."RELATIONSHIP_TYPE"= 'Contains'
      AND r."RELATED_GEO_ID"   LIKE 'zip/%'
), 
ranked AS (     -- rank growth within each year
    SELECT 
        g."YEAR",
        SUBSTR(g."GEO_ID", 5)               AS "ZIP_CODE",   -- drop 'zip/' prefix
        zs."STATE_ABBR",
        g."GROWTH_RATE",
        ROW_NUMBER() OVER (PARTITION BY g."YEAR" 
                           ORDER BY g."GROWTH_RATE" DESC NULLS LAST) AS rn
    FROM growth g
    LEFT JOIN zip_state zs
           ON g."GEO_ID" = zs."ZIP_GEO_ID"
)
SELECT 
    "YEAR",
    "ZIP_CODE",
    "STATE_ABBR",
    ROUND("GROWTH_RATE", 2) AS "ANNUAL_GROWTH_RATE_%"
FROM ranked
WHERE rn = 2                      -- second-highest growth per year
ORDER BY "YEAR";
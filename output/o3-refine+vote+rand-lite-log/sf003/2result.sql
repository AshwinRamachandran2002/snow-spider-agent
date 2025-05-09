/*-----------------------------------------------------------
  Find, for each year 2015‑2020, the Census ZCTA (zip/…..)  
  with the 2nd‑highest annual population growth rate, limited  
  to areas whose current‑year 5‑Year ACS population estimate  
  is ≥ 25,000.  
-----------------------------------------------------------*/
WITH pop AS (   -- 5‑Year ACS population estimates (Total Population)
    SELECT 
        "GEO_ID",                       -- e.g. zip/77095
        "DATE",
        TO_NUMBER(LEFT("DATE", 4)) AS "YEAR",
        TO_NUMBER("VALUE")      AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'         -- Total population, 5‑YR Estimate
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'
      AND "GEO_ID" LIKE 'zip/%'                  -- ZCTAs only
), pop_prev AS (                                 -- add previous‑year population
    SELECT 
        p1."GEO_ID",
        p1."YEAR",
        p1."POP",
        p0."POP"  AS "POP_PREV"
    FROM pop p1
    LEFT JOIN pop p0
      ON p0."GEO_ID" = p1."GEO_ID"
     AND p0."YEAR"  = p1."YEAR" - 1              -- previous ACS year
    WHERE p1."YEAR" BETWEEN 2015 AND 2020
), growth AS (                                   -- compute growth rate
    SELECT 
        "GEO_ID",
        "YEAR",
        "POP",
        "POP_PREV",
        (("POP" - "POP_PREV") / "POP_PREV") * 100     AS "GROWTH_PCT"
    FROM pop_prev
    WHERE "POP_PREV" > 0
      AND "POP"      >= 25000                      -- ≥ 25 000 people in current year
), state_xwalk AS (                               -- map ZIP → State abbreviation
    SELECT DISTINCT
        rel."RELATED_GEO_ID"          AS "ZIP_GEO_ID",
        REGEXP_SUBSTR(gi."ISO_3166_2_CODE", '[A-Z]{2}$') AS "STATE_ABBR"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS rel
    JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX gi
      ON gi."GEO_ID" = rel."GEO_ID"
    WHERE rel."RELATIONSHIP_TYPE" = 'Contains'
      AND rel."RELATED_GEO_ID" LIKE 'zip/%'
      AND rel."GEO_ID"          LIKE 'geoId/__/__%'  -- two‑digit state geoId (e.g. geoId/06)
), growth_with_state AS (
    SELECT 
        g."YEAR",
        SUBSTR(g."GEO_ID", 5)             AS "ZIP_CODE",      -- strip 'zip/' prefix
        sx."STATE_ABBR",
        g."GROWTH_PCT"
    FROM growth g
    LEFT JOIN state_xwalk sx
      ON sx."ZIP_GEO_ID" = g."GEO_ID"
)
SELECT 
    "YEAR",
    "ZIP_CODE",
    "STATE_ABBR",
    ROUND("GROWTH_PCT", 4) AS "ANNUAL_GROWTH_RATE_PCT"
FROM (
    SELECT 
        gw.*,
        DENSE_RANK() OVER (PARTITION BY "YEAR"
                           ORDER BY "GROWTH_PCT" DESC NULLS LAST) AS "RK"
    FROM growth_with_state gw
)
WHERE "RK" = 2                            -- second‑highest per year
ORDER BY "YEAR";
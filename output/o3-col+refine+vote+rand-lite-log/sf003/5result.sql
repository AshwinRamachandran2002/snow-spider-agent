-- Second–highest annual population-growth ZIP (≥25 k residents) for each year, 2015-2020
WITH
-- 1. 5-Year ACS total-population estimates for ZIP Code Tabulation Areas
pop AS (
    SELECT
        "GEO_ID",                                   -- e.g. zip/77494
        CAST("VALUE" AS FLOAT)           AS "population",
        YEAR("DATE")                    AS "yr"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'           -- total population, 5-YR estimate
      AND "GEO_ID"  LIKE 'zip/%'
      AND "DATE"    BETWEEN '2014-12-31' AND '2020-12-31'  -- need t-1 for growth calc
),
-- 2.  Year-over-year growth rates, keep ZIPs with ≥25 k residents in current year
growth AS (
    SELECT
        cur."GEO_ID",
        cur."yr"                               AS "year",
        cur."population"                       AS "pop_curr",
        prev."population"                      AS "pop_prev",
        100.0 * (cur."population" - prev."population") / NULLIF(prev."population",0) 
                                            AS "growth_pct"
    FROM pop cur
    JOIN pop prev
      ON prev."GEO_ID" = cur."GEO_ID"
     AND prev."yr"     = cur."yr" - 1
    WHERE cur."population" >= 25000           -- size threshold (current year)
      AND cur."yr" BETWEEN 2015 AND 2020
),
-- 3. Map each ZIP to its (single) containing State and extract the 2-letter code
zip_state AS (
    SELECT
        g."GEO_ID"                              AS "zip_geo_id",
        SUBSTR(gi."ISO_3166_2_CODE",4,2)        AS "state_abbrev"   -- e.g. 'US-CA' → 'CA'
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS g
    JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX gi
      ON gi."GEO_ID" = g."RELATED_GEO_ID"
    WHERE g."GEO_ID"        LIKE 'zip/%'
      AND g."RELATED_LEVEL" = 'State'
),
-- 4. Rank ZIPs by growth each year and pick the 2nd highest
ranked AS (
    SELECT
        gr."year",
        REPLACE(gr."GEO_ID",'zip/','')          AS "zip_code",
        zs."state_abbrev",
        gr."growth_pct",
        ROW_NUMBER() OVER (PARTITION BY gr."year"
                           ORDER BY gr."growth_pct" DESC NULLS LAST) AS rn
    FROM growth gr
    LEFT JOIN zip_state zs
      ON zs."zip_geo_id" = gr."GEO_ID"
)
SELECT
    "year",
    "zip_code",
    "state_abbrev",
    ROUND("growth_pct",4) AS "growth_rate_pct"
FROM ranked
WHERE rn = 2          -- second-highest per year
ORDER BY "year";
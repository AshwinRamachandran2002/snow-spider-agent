/*--------------------------------------------------------------------
  For each calendar year 2015-2020:
    • Calculate annual population-growth (%) for every ZIP code
      using ACS 5-Year “Total Population” (B01003_001E_5YR).
    • Keep ZIPs whose current-year population ≥ 25 000.
    • Pick the ZIP with the 2nd-highest growth rate in that year.
    • Return ZIP code, state abbreviation, and growth rate (%).
--------------------------------------------------------------------*/
WITH pop AS (  -- 5-Year ACS population values 2014-2020 for ZIP codes
    SELECT
        "GEO_ID",
        YEAR("DATE")          AS "YR",
        "VALUE"::FLOAT        AS "POP"
    FROM   GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE  "VARIABLE" = 'B01003_001E_5YR'
      AND  YEAR("DATE") BETWEEN 2014 AND 2020
      AND  "GEO_ID" LIKE 'zip/%'
),
growth AS (     -- year-over-year % growth (current vs. previous year)
    SELECT
        c."YR",
        c."GEO_ID",
        (c."POP" - p."POP") / p."POP" * 100.0          AS "GROWTH_PCT",
        c."POP"                                         AS "CURR_POP"
    FROM   pop p
    JOIN   pop c
           ON c."GEO_ID" = p."GEO_ID"
          AND c."YR"     = p."YR" + 1                  -- consecutive years
    WHERE  c."YR" BETWEEN 2015 AND 2020
      AND  c."POP" >= 25000                           -- ≥ 25 000 population
),
ranked AS (      -- rank ZIPs by growth within each year
    SELECT
        g.*,
        ROW_NUMBER() OVER (PARTITION BY g."YR"
                           ORDER BY g."GROWTH_PCT" DESC NULLS LAST) AS "RN"
    FROM   growth g
),
state_map AS (   -- map ZIP → state & grab state ISO code
    SELECT
        gr."RELATED_GEO_ID"          AS "ZIP_GEO_ID",
        gi."ISO_3166_2_CODE"         AS "STATE_CODE"
    FROM   GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS gr
    JOIN   GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX gi
          ON gi."GEO_ID" = gr."GEO_ID"
    WHERE  gr."RELATIONSHIP_TYPE" = 'Contains'
      AND  gr."LEVEL"             = 'State'
      AND  gr."RELATED_LEVEL"     = 'CensusZipCodeTabulationArea'
)

SELECT
    r."YR"                                           AS "YEAR",
    SUBSTR(r."GEO_ID", 5)                            AS "ZIP_CODE",
    SPLIT_PART(sm."STATE_CODE", '-', 2)              AS "STATE",
    ROUND(r."GROWTH_PCT", 2)                         AS "ANNUAL_GROWTH_%"
FROM   ranked r
LEFT  JOIN state_map sm
       ON sm."ZIP_GEO_ID" = r."GEO_ID"
WHERE  r."RN" = 2                                    -- 2nd-highest per year
ORDER  BY r."YR";
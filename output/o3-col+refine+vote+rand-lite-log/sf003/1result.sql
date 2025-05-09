/* ------------------------------------------------------------
   Second–highest ZIP-code population growth (≥25 k pop)
   for each year 2015-2020 using ACS 5-Year estimates
   ------------------------------------------------------------ */
WITH pop AS (                                   -- yearly ZIP populations
    SELECT
        "GEO_ID",
        EXTRACT(year FROM "DATE")  AS "YR",
        "VALUE"::FLOAT            AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE"  = 'B01003_001E_5YR'       -- 5-yr total-population
      AND "GEO_ID"    LIKE 'zip/%'              -- Census ZIP Code Tabulation Areas
      AND "DATE" BETWEEN '2014-01-01' AND '2020-12-31'
), growth AS (                                  -- year-over-year % growth
    SELECT
        cur."GEO_ID",
        cur."YR",
        100.0 * (cur."POP" - prv."POP") / NULLIF(prv."POP",0)  AS "GR_PCT",
        cur."POP"
    FROM pop cur
    JOIN pop prv
      ON cur."GEO_ID" = prv."GEO_ID"
     AND cur."YR"     = prv."YR" + 1
    WHERE cur."YR" BETWEEN 2015 AND 2020        -- target years
      AND cur."POP" >= 25000                    -- ≥25 k population in current year
), ranked AS (                                  -- rank by growth within each year
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "YR"
                           ORDER BY "GR_PCT" DESC NULLS LAST) AS "RN"
    FROM growth
), second AS (                                  -- 2nd-highest ZIP each year
    SELECT "GEO_ID", "YR", "GR_PCT"
    FROM   ranked
    WHERE  "RN" = 2
), state_map AS (                               -- map ZIP → State GEO_ID
    SELECT DISTINCT
           r."RELATED_GEO_ID"  AS "ZIP_ID",     -- zip/xxxxx
           r."GEO_ID"          AS "STATE_GEO_ID"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS r
    WHERE r."LEVEL"             = 'State'
      AND r."RELATED_LEVEL"     = 'CensusZipCodeTabulationArea'
      AND r."RELATIONSHIP_TYPE" = 'Contains'
), state_abbr AS (                              -- derive 2-letter abbreviation
    SELECT
        g."GEO_ID",
        SPLIT_PART(g."ISO_3166_2_CODE", '-', 2) AS "STATE_ABBR"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX g
    WHERE g."LEVEL" = 'State'
)
SELECT
    s."YR"                                   AS "YEAR",
    SPLIT_PART(s."GEO_ID", '/', 2)           AS "ZIP_CODE",
    sa."STATE_ABBR"                          AS "STATE",
    ROUND(s."GR_PCT", 4)                     AS "ANNUAL_GROWTH_PERCENT"
FROM       second     s
LEFT JOIN  state_map  sm ON s."GEO_ID"      = sm."ZIP_ID"
LEFT JOIN  state_abbr sa ON sm."STATE_GEO_ID" = sa."GEO_ID"
ORDER BY    "YEAR";
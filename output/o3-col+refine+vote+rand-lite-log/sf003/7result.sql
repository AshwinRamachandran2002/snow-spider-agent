/*  Second-highest annual population growth (>=25 k population) for ZCTAs,
    by year 2015-2020, using 5-Year ACS estimates                                    */

WITH acs_zcta AS (           -- total-population 5-year ACS estimates for ZIP ZCTAs
    SELECT
        "GEO_ID",
        "DATE",
        "VALUE"                       AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE"  = 'B01003_001E_5YR'          -- total population (5-YR estimate)
      AND "GEO_ID"    LIKE 'zip/%'                 -- keep only Census ZCTAs
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'
),

yr_pairs AS (                -- year-over-year population & growth %
    SELECT
        b."GEO_ID",
        YEAR(b."DATE")                                        AS "YEAR",
        a."POP"                                               AS "POP_PREV",
        b."POP"                                               AS "POP_CURR",
        (b."POP" - a."POP") / NULLIF(a."POP",0) * 100         AS "GROWTH_PCT"
    FROM acs_zcta a
    JOIN acs_zcta b
      ON a."GEO_ID" = b."GEO_ID"
     AND DATEADD(year,1,a."DATE") = b."DATE"      -- pair consecutive ACS years
),

eligible AS (                -- apply population ≥ 25 k filter on CURRENT year
    SELECT *
    FROM yr_pairs
    WHERE "YEAR" BETWEEN 2015 AND 2020           -- results wanted for 2015-2020
      AND "POP_CURR" >= 25000
),

ranked AS (                  -- rank ZCTAs by growth rate within each year
    SELECT
        e.*,
        ROW_NUMBER() OVER (PARTITION BY e."YEAR"
                           ORDER BY e."GROWTH_PCT" DESC NULLS LAST) AS "RN"
    FROM eligible e
)

SELECT
    r."YEAR",
    SPLIT_PART(r."GEO_ID", '/', 2)                              AS "ZIP_CODE",
    REGEXP_REPLACE(gs."ISO_3166_2_CODE", 'US-', '')             AS "STATE_ABBREVIATION",
    ROUND(r."GROWTH_PCT", 2)                                    AS "ANNUAL_GROWTH_PERCENT"
FROM ranked r
LEFT JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS gr   -- map ZCTA → state
       ON gr."RELATED_GEO_ID"   = r."GEO_ID"
      AND gr."RELATED_LEVEL"    = 'CensusZipCodeTabulationArea'
      AND gr."LEVEL"            = 'State'
      AND gr."RELATIONSHIP_TYPE"= 'Contains'
LEFT JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX gs
       ON gs."GEO_ID" = gr."GEO_ID"
WHERE r."RN" = 2                                                  -- 2nd-highest
ORDER BY r."YEAR";
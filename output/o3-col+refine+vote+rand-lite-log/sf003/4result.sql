WITH pop AS (   -- yearly 5-year ACS population estimates for ZIP Code Tabulation Areas
    SELECT 
        "GEO_ID",
        "DATE",
        "VALUE"::FLOAT AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'            -- total population (estimate)
      AND "GEO_ID" ILIKE 'zip/%'                   -- keep ZIP ZCTAs only
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'
), pairs AS (   -- compute annual growth (current vs. prior year)
    SELECT
        cur."GEO_ID",
        cur."DATE"                       AS "CUR_DATE",
        (cur."POP" - prev."POP") / NULLIF(prev."POP",0) * 100 AS "GROWTH_PCT"
    FROM pop cur
    JOIN pop prev
      ON prev."GEO_ID" = cur."GEO_ID"
     AND prev."DATE"   = DATEADD(year,-1,cur."DATE")
    WHERE cur."POP" >= 25000                             -- population threshold
), state_map AS (   -- map each ZIP to its containing state & abbreviation
    SELECT
        rel."RELATED_GEO_ID"              AS "ZIP_GEO_ID",
        idx."ISO_ALPHA2"                  AS "STATE_ABBR"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS rel
    JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX idx
          ON idx."GEO_ID" = rel."GEO_ID"
    WHERE rel."LEVEL"            = 'State'
      AND rel."RELATED_LEVEL"    = 'CensusZipCodeTabulationArea'
      AND rel."RELATIONSHIP_TYPE"= 'Contains'
      AND idx."ISO_ALPHA2" IS NOT NULL
), ranked AS (   -- rank ZIPs by growth rate for each year
    SELECT
        YEAR("CUR_DATE")                               AS "YEAR",
        SUBSTR(p."GEO_ID",5)                           AS "ZIP_CODE",
        sm."STATE_ABBR",
        p."GROWTH_PCT",
        ROW_NUMBER() OVER (PARTITION BY YEAR("CUR_DATE") 
                           ORDER BY p."GROWTH_PCT" DESC NULLS LAST) AS "RN"
    FROM pairs p
    JOIN state_map sm
      ON sm."ZIP_GEO_ID" = p."GEO_ID"
)
SELECT
    "YEAR",
    "ZIP_CODE",
    "STATE_ABBR",
    ROUND("GROWTH_PCT",2)          AS "ANNUAL_GROWTH_RATE_%"
FROM ranked
WHERE "RN" = 2                     -- second-highest growth each year
ORDER BY "YEAR";
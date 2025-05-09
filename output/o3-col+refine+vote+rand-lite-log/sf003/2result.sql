WITH pop AS (   -- 5-Year ACS total-population for ZIP Code Tabulation Areas
    SELECT
        "GEO_ID",
        YEAR("DATE")                         AS "YEAR",
        "VALUE"::FLOAT                       AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'     -- total population, 5-yr estimate
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'
      AND "GEO_ID" LIKE 'zip/%'              -- keep only ZCTAs
),
growth AS (      -- year-over-year growth %
    SELECT
        cur."GEO_ID",
        cur."YEAR",
        ROUND( (cur."POP" - prev."POP") / NULLIF(prev."POP",0) * 100 , 6)  AS "GROWTH_PCT"
    FROM pop cur
    JOIN pop prev
      ON cur."GEO_ID" = prev."GEO_ID"
     AND cur."YEAR"   = prev."YEAR" + 1
    WHERE cur."POP" >= 25000               -- ≥25k residents in current year
),
ranked AS (      -- rank by growth within each year
    SELECT
        "YEAR",
        "GEO_ID",
        "GROWTH_PCT",
        ROW_NUMBER() OVER (PARTITION BY "YEAR" ORDER BY "GROWTH_PCT" DESC NULLS LAST) AS "RN"
    FROM growth
    WHERE "YEAR" BETWEEN 2015 AND 2020
)
SELECT
    SUBSTR(rk."GEO_ID", 5)                            AS "ZIP_CODE",
    /* derive two-letter state abbreviation where possible */
    COALESCE(g."ISO_ALPHA2",
             RIGHT(g."ISO_3166_2_CODE",2),
             g."GEO_NAME")                            AS "STATE_ABBR",
    rk."YEAR",
    ROUND(rk."GROWTH_PCT", 4)                         AS "ANNUAL_GROWTH_PCT"
FROM ranked rk
LEFT JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS gr
       ON gr."RELATED_GEO_ID" = rk."GEO_ID"
      AND gr."RELATIONSHIP_TYPE" = 'Contains'         -- state contains zip
LEFT JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX g
       ON g."GEO_ID" = gr."GEO_ID"
      AND g."LEVEL" = 'State'
WHERE rk."RN" = 2                                     -- 2nd-highest per year
ORDER BY rk."YEAR";
/* 2nd-fastest growing ≥25k-population ZIP Code (ZCTA) for each year 2015-2020 */

WITH pop AS (   -- pull 5-year ACS total-population estimates for ZIP ZCTAs
    SELECT
        "GEO_ID",
        YEAR("DATE")             AS "YR",
        "VALUE"::FLOAT           AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'         -- Total population (5-Year estimate)
      AND "GEO_ID"  LIKE 'zip/%'
      AND YEAR("DATE") BETWEEN 2014 AND 2020
),
growth AS (      -- compute year-over-year growth %
    SELECT
        cur."GEO_ID",
        cur."YR",
        100.0 * (cur."POP" - pr."POP") / pr."POP"  AS "GROWTH_PCT"
    FROM pop cur
    JOIN pop pr
      ON  pr."GEO_ID" = cur."GEO_ID"
      AND pr."YR"     = cur."YR" - 1
    WHERE cur."POP" >= 25000                      -- keep ≥25k population ZIPs
),
ranked AS (      -- rank growth within each year
    SELECT
        g.*,
        DENSE_RANK() OVER (PARTITION BY g."YR"
                           ORDER BY g."GROWTH_PCT" DESC NULLS LAST) AS "RNK"
    FROM growth g
)
SELECT
    r."YR"                                            AS "YEAR",
    SUBSTR(r."GEO_ID",5)                              AS "ZIP_CODE",
    s."ISO_3166_2_CODE"                               AS "STATE_ABBR",
    ROUND(r."GROWTH_PCT",2)                           AS "ANNUAL_GROWTH_PCT"
FROM ranked r
JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS gr
  ON gr."RELATED_GEO_ID" = r."GEO_ID"
 AND gr."RELATIONSHIP_TYPE" = 'Contains'
JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX s      -- state abbreviation
  ON s."GEO_ID" = gr."GEO_ID"
 AND s."LEVEL"  = 'State'
WHERE r."RNK" = 2                                     -- 2nd-highest growth per year
  AND r."YR" BETWEEN 2015 AND 2020
ORDER BY r."YR";
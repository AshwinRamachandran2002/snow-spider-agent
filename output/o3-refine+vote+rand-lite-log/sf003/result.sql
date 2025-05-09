/* Second–highest annual population growth rate (ACS 5‑Year) for ZCTAs, 2015‑2020 */
WITH pop AS (          /* Total population (5‑year estimate) */
    SELECT
        "GEO_ID",
        TO_NUMBER(LEFT("DATE", 4))            AS "YEAR",
        CAST("VALUE" AS FLOAT)                AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'      -- Total population, estimate, 5‑yr
      AND "GEO_ID"  LIKE 'zip/%'              -- Limit to ZCTAs
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'   -- Need t and t‑1
), growth AS (        /* Year‑over‑year % growth, keep ≥25k pop */
    SELECT
        c."GEO_ID",
        c."YEAR",
        100.0 * (c."POP" - p."POP") / p."POP" AS "GROWTH_PCT",
        c."POP"
    FROM pop c
    JOIN pop p
      ON p."GEO_ID" = c."GEO_ID"
     AND p."YEAR"   = c."YEAR" - 1            -- Previous year
    WHERE c."YEAR" BETWEEN 2015 AND 2020
      AND c."POP"  >= 25000                  -- Current‑year pop threshold
), ranked AS (       /* Rank by growth within each year */
    SELECT
        g.*,
        ROW_NUMBER() OVER (PARTITION BY g."YEAR"
                           ORDER BY g."GROWTH_PCT" DESC NULLS LAST) AS "RN"
    FROM growth g
)
SELECT
    SUBSTR(r."GEO_ID", 5)                                            AS "ZIP_CODE",
    SUBSTR(SPLIT_PART(s."ISO_3166_2_CODE", '-', 2), 1, 2)            AS "STATE_ABBR",
    ROUND(r."GROWTH_PCT", 4)                                         AS "ANNUAL_GROWTH_RATE_PCT",
    r."YEAR"
FROM ranked r
JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS rel
      ON rel."RELATED_GEO_ID"   = r."GEO_ID"
     AND rel."LEVEL"            = 'State'
     AND rel."RELATIONSHIP_TYPE" = 'Contains'
JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX s
      ON s."GEO_ID" = rel."GEO_ID"
WHERE r."RN" = 2                                    -- 2nd‑highest growth in each year
ORDER BY r."YEAR", "ZIP_CODE";
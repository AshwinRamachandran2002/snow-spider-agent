WITH pop AS (   -- 5-Year ACS population by ZIP and calendar year
    SELECT
        "GEO_ID",
        YEAR("DATE")                AS "YEAR",
        "VALUE"::FLOAT              AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01001_001E_5YR'
      AND "GEO_ID"   LIKE 'zip/%'
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'
), 
growth AS (      -- compute annual growth 2015-2020
    SELECT
        c."GEO_ID",
        c."YEAR"                              AS "YEAR",
        c."POP"                               AS "POP_CURR",
        p."POP"                               AS "POP_PREV",
        (c."POP" - p."POP")/p."POP"*100       AS "GROWTH_PCT"
    FROM pop c
    JOIN pop p
      ON c."GEO_ID" = p."GEO_ID"
     AND c."YEAR"   = p."YEAR" + 1            -- previous year
    WHERE c."YEAR" BETWEEN 2015 AND 2020
      AND c."POP"   >= 25000                  -- ≥25k residents in current year
      AND p."POP"   > 0                       -- avoid divide-by-zero
), 
ranked AS (      -- pick 2nd-highest growth each year
    SELECT
        g.*,
        ROW_NUMBER() OVER (PARTITION BY g."YEAR"
                           ORDER BY g."GROWTH_PCT" DESC) AS rn
    FROM growth g
)
SELECT
    r."YEAR",
    SUBSTR(r."GEO_ID", 5)                    AS "ZIP_CODE",
    s."ISO_3166_2_CODE"                      AS "STATE_ABBR",
    ROUND(r."GROWTH_PCT", 4)                 AS "GROWTH_PCT"
FROM ranked r
JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS gr
     ON gr."RELATED_GEO_ID"   = r."GEO_ID"
    AND gr."RELATIONSHIP_TYPE" = 'Contains'
JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX s
     ON s."GEO_ID" = gr."GEO_ID"
    AND s."LEVEL"  = 'State'
WHERE r.rn = 2                                -- second-highest per year
ORDER BY r."YEAR";
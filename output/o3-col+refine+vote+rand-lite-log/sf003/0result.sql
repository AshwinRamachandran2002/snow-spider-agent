-- Second-highest annual population growth ZIP Code (≥25k pop) for each year 2015-2020
WITH pop AS (          -- pull 2014-2020 5-Year ACS population estimates for all ZIP ZCTAs
    SELECT
        "GEO_ID",
        YEAR("DATE")                    AS "YEAR",
        "VALUE"::FLOAT                  AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'        -- total population, 5-Year estimate
      AND "GEO_ID"  LIKE 'zip/%'
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'
), growth AS (        -- compute YoY % growth for each ZIP
    SELECT
        p.*,
        (p."POP" - LAG(p."POP") OVER (PARTITION BY p."GEO_ID" ORDER BY p."YEAR"))
        / NULLIF(LAG(p."POP") OVER (PARTITION BY p."GEO_ID" ORDER BY p."YEAR"),0) * 100
            AS "GROWTH_PCT"
    FROM pop p
), filt AS (          -- keep target years, pop ≥25k, and valid growth rate
    SELECT *
    FROM   growth
    WHERE  "YEAR" BETWEEN 2015 AND 2020
      AND  "POP"  >= 25000
      AND  "GROWTH_PCT" IS NOT NULL
), ranked AS (        -- rank ZIPs by growth within each year
    SELECT
        f.*,
        DENSE_RANK() OVER (PARTITION BY f."YEAR" ORDER BY f."GROWTH_PCT" DESC) AS "RNK"
    FROM   filt f
), states AS (        -- map ZIPs to state postal abbreviations
    SELECT
        gr."GEO_ID"                           AS "ZIP_GEO_ID",
        MIN(gi."ISO_3166_2_CODE")             AS "STATE_ABBR"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS gr
    JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX        gi
         ON gr."RELATED_GEO_ID" = gi."GEO_ID"
    WHERE gr."GEO_ID" LIKE 'zip/%'
      AND gi."LEVEL"  = 'State'
    GROUP BY gr."GEO_ID"
)
SELECT
    r."YEAR",
    SPLIT_PART(r."GEO_ID", '/', 2)            AS "ZIP_CODE",
    s."STATE_ABBR",
    ROUND(r."GROWTH_PCT", 2)                  AS "ANNUAL_GROWTH_PCT"
FROM   ranked r
LEFT JOIN states s
       ON r."GEO_ID" = s."ZIP_GEO_ID"
WHERE  r."RNK" = 2                            -- second-highest growth each year
ORDER  BY r."YEAR";
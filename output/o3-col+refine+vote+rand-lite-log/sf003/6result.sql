WITH pop AS (   -- total-population (5-YR ACS) by ZIP and year
    SELECT
        "GEO_ID",
        DATE_PART('year',"DATE")         AS "YR",
        "VALUE"::FLOAT                   AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'             -- total-population estimate
      AND "GEO_ID"   LIKE 'zip/%'                    -- ZIP (CZCTA) only
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'
), lagged AS (   -- bring forward prior-year population to compute growth
    SELECT
        "GEO_ID",
        "YR",
        "POP",
        LAG("POP") OVER (PARTITION BY "GEO_ID" ORDER BY "YR") AS "POP_PRIOR"
    FROM pop
), growth AS (   -- annual growth %
    SELECT
        "GEO_ID",
        "YR",
        ("POP" - "POP_PRIOR") / NULLIF("POP_PRIOR",0) * 100   AS "GROWTH_PCT",
        "POP"
    FROM lagged
    WHERE "YR" BETWEEN 2015 AND 2020          -- years of interest
      AND "POP" >= 25000                      -- ≥ 25 000 population that year
), ranked AS (   -- rank ZIPs by growth within each year
    SELECT
        g.*,
        ROW_NUMBER() OVER (PARTITION BY "YR" ORDER BY "GROWTH_PCT" DESC NULLS LAST) AS "RN"
    FROM growth g
), second_best AS (  -- keep 2nd-highest grower per year
    SELECT
        "GEO_ID",
        "YR",
        "GROWTH_PCT"
    FROM ranked
    WHERE "RN" = 2
), add_state AS (   -- attach state abbreviation (postal code)
    SELECT
        sb.*,
        -- join where the state "contains" the ZIP
        COALESCE(si."ISO_ALPHA2",
                 SUBSTR(si."ISO_3166_2_CODE", -2),     -- e.g., 'US-CA' → 'CA'
                 si."ISO_NAME")                        AS "STATE_ABBV"
    FROM second_best sb
    LEFT JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS gr
           ON gr."RELATED_GEO_ID" = sb."GEO_ID"
          AND gr."LEVEL"          = 'State'
    LEFT JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX si
           ON si."GEO_ID" = gr."GEO_ID"
          AND si."LEVEL"  = 'State'
)
SELECT
    "YR"                                           AS "YEAR",
    SPLIT_PART("GEO_ID", '/', 2)                  AS "ZIP_CODE",
    "STATE_ABBV",
    ROUND("GROWTH_PCT", 2)                        AS "ANNUAL_GROWTH_PCT"
FROM add_state
ORDER BY "YEAR";
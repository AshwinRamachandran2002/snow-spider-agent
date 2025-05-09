/*  Second–highest annual population growth (ACS 5‑Year) for ZCTAs, 2015‑2020  */
WITH pop AS (   -- pull 2014‑2020 population for every ZCTA
    SELECT
        "GEO_ID",
        TO_NUMBER("VALUE")                  AS "POP",
        YEAR("DATE")                        AS "YEAR"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'        -- total population, 5‑Year ACS
      AND "GEO_ID" LIKE 'zip/%'
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'
),
pop_with_lag AS (   -- previous‑year population for growth calc
    SELECT
        p.*,
        LAG("POP")  OVER (PARTITION BY "GEO_ID" ORDER BY "YEAR") AS "PREV_POP",
        LAG("YEAR") OVER (PARTITION BY "GEO_ID" ORDER BY "YEAR") AS "PREV_YEAR"
    FROM pop p
),
growth AS (   -- annual growth % for 2015‑2020, keep ZCTAs ≥25 000 in current year
    SELECT
        "GEO_ID",
        "YEAR",
        (("POP" - "PREV_POP") / NULLIF("PREV_POP",0)) * 100       AS "GROWTH_PCT"
    FROM pop_with_lag
    WHERE "YEAR" BETWEEN 2015 AND 2020
      AND "PREV_YEAR" = "YEAR" - 1
      AND "POP" >= 25000
),
ranked AS (   -- rank ZCTAs by growth within each year
    SELECT
        g.*,
        ROW_NUMBER() OVER (PARTITION BY "YEAR"
                           ORDER BY "GROWTH_PCT" DESC NULLS LAST, "GEO_ID") AS "RN"
    FROM growth g
),
second_place AS (   -- keep the 2nd‑highest growth ZCTA per year
    SELECT * FROM ranked WHERE "RN" = 2
),
-- map each ZCTA to its state for abbreviation
state_lookup AS (
    SELECT
        r."RELATED_GEO_ID" AS "ZCTA_GEO_ID",
        i."ISO_ALPHA2"     AS "STATE_ABBR"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS r
    JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX        i
      ON i."GEO_ID" = r."GEO_ID"
    WHERE r."LEVEL"         = 'State'
      AND r."RELATED_LEVEL" = 'CensusZipCodeTabulationArea'
)
SELECT
    s."YEAR",
    SUBSTR(s."GEO_ID", 5)        AS "ZIP_CODE",
    sl."STATE_ABBR",
    ROUND(s."GROWTH_PCT", 4)     AS "GROWTH_RATE_PCT"
FROM second_place s
LEFT JOIN state_lookup sl
       ON sl."ZCTA_GEO_ID" = s."GEO_ID"
ORDER BY s."YEAR";
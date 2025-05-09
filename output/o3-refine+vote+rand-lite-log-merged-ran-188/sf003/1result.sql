WITH population AS (   -- 5‑Year ACS total‑population estimates for ZIP (CZCTA) level
    SELECT
        DATE_PART('year', "DATE")                         AS "YEAR",
        "GEO_ID",                                         -- e.g. zip/30301
        TO_NUMBER("VALUE")                                AS "POP"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'                  -- Total population, 5‑Year estimate
      AND "GEO_ID"  LIKE 'zip/%'
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'    -- need t‑1 and t values
),
growth AS (            -- year‑over‑year growth rate %
    SELECT
        cur."YEAR"                                    AS "YEAR",
        cur."GEO_ID",
        (cur."POP" - prev."POP") / prev."POP"         AS "GROWTH_RATE",   -- fraction
        cur."POP"                                     AS "POP_CUR"
    FROM population cur
    JOIN population prev
          ON prev."GEO_ID" = cur."GEO_ID"
         AND prev."YEAR"   = cur."YEAR" - 1
    WHERE cur."POP" >= 25000                          -- at least 25k in the CURRENT year
      AND cur."YEAR" BETWEEN 2015 AND 2020
),
zip_to_county AS (     -- map ZIP to its containing county
    SELECT
        "RELATED_GEO_ID"  AS "ZIP_GEO_ID",
        "GEO_ID"          AS "COUNTY_GEO_ID"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS
    WHERE "RELATED_LEVEL"     = 'CensusZipCodeTabulationArea'
      AND "LEVEL"             = 'County'
      AND "RELATIONSHIP_TYPE" = 'Contains'
),
state_lookup AS (      -- state abbreviation from geography index
    SELECT
        "GEO_ID"                                       AS "STATE_GEO_ID",
        REGEXP_REPLACE("ISO_3166_2_CODE", 'US-', '')   AS "STATE_ABBR"
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX
    WHERE "LEVEL" = 'State'
      AND "ISO_3166_2_CODE" IS NOT NULL
),
ranked AS (            -- rank ZIPs by growth rate, descending
    SELECT
        g."YEAR",
        g."GEO_ID",
        g."GROWTH_RATE",
        ROW_NUMBER() OVER (PARTITION BY g."YEAR"
                           ORDER BY g."GROWTH_RATE" DESC NULLS LAST,
                                    g."GEO_ID")       AS "RN"
    FROM growth g
)
SELECT
    r."YEAR",
    SUBSTR(r."GEO_ID", 5)                    AS "ZIP_CODE",
    s."STATE_ABBR"                           AS "STATE",
    ROUND(r."GROWTH_RATE" * 100, 4)          AS "ANNUAL_GROWTH_RATE_PCT"
FROM ranked r
LEFT JOIN zip_to_county z
       ON z."ZIP_GEO_ID" = r."GEO_ID"
LEFT JOIN state_lookup s
       ON s."STATE_GEO_ID" = 'geoId/' || SUBSTR(SPLIT_PART(z."COUNTY_GEO_ID", '/', 2), 1, 2)
WHERE r."RN" = 2                              -- second‑highest per year
ORDER BY r."YEAR";
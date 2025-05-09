WITH pop AS (
    /* 5‑Year ACS total‑population estimates for ZIP Code Tabulation Areas */
    SELECT
        "GEO_ID",                              -- e.g. zip/94110
        YEAR("DATE")              AS yr,       -- calendar year (2014‑2020 kept for lag)
        TO_NUMBER("VALUE")        AS pop
    FROM GLOBAL_GOVERNMENT.CYBERSYN.AMERICAN_COMMUNITY_SURVEY_TIMESERIES
    WHERE "VARIABLE" = 'B01003_001E_5YR'       -- total population, 5‑Year estimate
      AND "GEO_ID" LIKE 'zip/%'
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'
),
growth AS (
    /* year‑over‑year growth rates */
    SELECT
        p."GEO_ID",
        p.yr,
        p.pop,
        LAG(p.pop) OVER (PARTITION BY p."GEO_ID" ORDER BY p.yr)   AS prev_pop,
        100.0 * (p.pop - LAG(p.pop) OVER (PARTITION BY p."GEO_ID" ORDER BY p.yr))
              / NULLIF(LAG(p.pop) OVER (PARTITION BY p."GEO_ID" ORDER BY p.yr),0)       AS growth_pct
    FROM pop p
),
growth_filtered AS (
    /* keep 2015‑2020 rows with ≥25 000 population in the current year */
    SELECT *
    FROM growth
    WHERE yr BETWEEN 2015 AND 2020
      AND pop >= 25000
      AND prev_pop IS NOT NULL
),
state_map AS (
    /* map ZIP -> state abbreviation (e.g. CA, TX …) */
    SELECT
        gr."RELATED_GEO_ID"   AS zip_geo_id,          -- zip/NNNNN
        SUBSTR(gi."ISO_3166_2_CODE", 4) AS state_abbr -- extract 'CA' from 'US-CA'
    FROM GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_RELATIONSHIPS gr
    JOIN GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX       gi
          ON gi."GEO_ID" = gr."GEO_ID"                    -- state row
    WHERE gr."RELATIONSHIP_TYPE" = 'Contains'
      AND gr."LEVEL"            = 'State'
      AND gr."RELATED_LEVEL"    = 'CensusZipCodeTabulationArea'
),
ranked AS (
    /* rank ZIPs by growth rate per year */
    SELECT
        g.yr,
        SPLIT_PART(g."GEO_ID", '/', 2) AS zip_code,
        sm.state_abbr,
        g.growth_pct,
        ROW_NUMBER() OVER (PARTITION BY g.yr ORDER BY g.growth_pct DESC NULLS LAST, g."GEO_ID") AS rn
    FROM growth_filtered g
    LEFT JOIN state_map sm
           ON sm.zip_geo_id = g."GEO_ID"
)
SELECT
    yr               AS "YEAR",
    zip_code         AS "ZIP_CODE",
    state_abbr       AS "STATE",
    ROUND(growth_pct, 4) AS "ANNUAL_GROWTH_RATE_PCT"
FROM ranked
WHERE rn = 2      -- second‑highest per year
ORDER BY yr;
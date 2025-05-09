WITH pop AS (  -- 5-Year ACS population for ZIP Code Tabulation Areas
    SELECT
        "GEO_ID",
        TO_NUMBER(TO_CHAR("DATE", 'YYYY'))               AS "YEAR",
        "VALUE"::FLOAT                                   AS population
    FROM GLOBAL_GOVERNMENT.CYBERSYN."AMERICAN_COMMUNITY_SURVEY_TIMESERIES"
    WHERE "VARIABLE" = 'B01003_001E_5YR'          -- total population, 5-Year estimate
      AND "DATE" BETWEEN '2014-12-31' AND '2020-12-31'
      AND "GEO_ID" LIKE 'zip/%'
),
pop_prev AS (  -- bring in previous-year population
    SELECT
        p.*,
        LAG(population) OVER (PARTITION BY "GEO_ID" ORDER BY "YEAR") AS population_prev
    FROM pop p
),
growth AS (    -- compute Y/Y growth rate and keep ZIPs ≥ 25k residents
    SELECT
        "GEO_ID",
        "YEAR",
        population,
        population_prev,
        CASE WHEN population_prev > 0
             THEN (population - population_prev) / population_prev * 100
        END                                            AS growth_rate
    FROM pop_prev
    WHERE "YEAR" BETWEEN 2015 AND 2020            -- target output years
      AND population     >= 25000                 -- ≥ 25 000 residents (current year)
      AND population_prev IS NOT NULL
),
-- map ZIP ⇒ state (via county relationship, then state FIPS → 2-letter code)
zip_to_state_fips AS (
    SELECT
        "GEO_ID"                                         AS zip_geoid,
        SUBSTRING("RELATED_GEO_ID", 7, 2)                AS state_fips
    FROM GLOBAL_GOVERNMENT.CYBERSYN."GEOGRAPHY_RELATIONSHIPS"
    WHERE "GEO_ID"        LIKE 'zip/%'
      AND "RELATED_LEVEL" = 'County'
),
zip_state AS (
    SELECT zip_geoid, MIN(state_fips) AS state_fips     -- if ZIP overlaps >1 county
    FROM zip_to_state_fips
    GROUP BY zip_geoid
),
state_abbr AS (
    SELECT
        "GEO_ID"                                         AS state_geoid,
        RIGHT("ISO_ALPHA2", 2)                           AS state_abbr
    FROM GLOBAL_GOVERNMENT.CYBERSYN."GEOGRAPHY_INDEX"
    WHERE "LEVEL" = 'State'
),
ranked AS (   -- rank ZIPs by growth rate within each year
    SELECT
        g.*,
        ROW_NUMBER() OVER (PARTITION BY "YEAR"
                           ORDER BY growth_rate DESC NULLS LAST) AS rn
    FROM growth g
)
SELECT
    r."YEAR"                                   AS year,
    SPLIT_PART(r."GEO_ID", '/', 2)             AS zip_code,
    sa.state_abbr,
    ROUND(r.growth_rate, 4)                    AS growth_rate_percent
FROM ranked            r
JOIN zip_state         zs ON zs.zip_geoid   = r."GEO_ID"
JOIN state_abbr        sa ON sa.state_geoid = 'geoId/' || zs.state_fips
WHERE r.rn = 2                                 -- second-highest per year
ORDER BY year;
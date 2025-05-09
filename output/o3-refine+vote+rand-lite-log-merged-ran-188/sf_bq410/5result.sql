WITH
-- 2017 tract–level counts used to build the adjusted non‑labor‑force metric
tract17 AS (
    SELECT
        "geo_id",
        COALESCE("unemployed_pop",0)           AS unemployed_pop,
        COALESCE("not_in_labor_force",0)       AS not_in_labor_force,
        COALESCE("group_quarters",0)           AS group_quarters,
        COALESCE("total_pop",0)                AS total_pop
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2017_5YR
),

-- Median income for the two comparison years
income15 AS (
    SELECT "geo_id", "median_income" AS median_income_2015
    FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2015_5YR
),
income18 AS (
    SELECT "geo_id", "median_income" AS median_income_2018
    FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2018_5YR
),

-- Join 2017 counts with the two income years and build tract‑level measures
tract_combined AS (
    SELECT
        t."geo_id",
        SUBSTR(t."geo_id",1,2)                                                AS state_fips,
        GREATEST(  -- adjusted non‑labor‑force population, clamped at ≥0
            unemployed_pop + not_in_labor_force - group_quarters , 0
        )                                                                     AS adjusted_nlf,
        total_pop,
        (i18.median_income_2018 - i15.median_income_2015)                     AS income_diff
    FROM tract17           t
    JOIN income15          i15 ON i15."geo_id" = t."geo_id"
    JOIN income18          i18 ON i18."geo_id" = t."geo_id"
    WHERE (i18.median_income_2018 - i15.median_income_2015) IS NOT NULL
),

-- Aggregate to state level
state_rollup AS (
    SELECT
        state_fips,
        SUM(income_diff)                                   AS total_median_income_change,
        SUM(adjusted_nlf)                                  AS total_adjusted_nlf,
        AVG(CASE WHEN total_pop > 0
                 THEN adjusted_nlf / total_pop
            END)                                          AS avg_prop
    FROM tract_combined
    GROUP BY state_fips
),

-- Attach state postal abbreviations
state_named AS (
    SELECT
        sf."postal_code"                                   AS state_abbrev,
        r.total_median_income_change,
        r.total_adjusted_nlf,
        r.avg_prop
    FROM state_rollup r
    LEFT JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS sf
           ON sf."fips" = TO_NUMBER(r.state_fips)
)

-- Return the three states with the smallest adjusted non‑labor‑force totals
SELECT
    state_abbrev,
    total_median_income_change,
    total_adjusted_nlf,
    avg_prop
FROM state_named
ORDER BY total_adjusted_nlf ASC, state_abbrev
FETCH FIRST 3 ROWS ONLY;
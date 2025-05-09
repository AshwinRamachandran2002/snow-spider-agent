WITH

-- 2017 tract–level populations
tract17 AS (
    SELECT
        "geo_id",
        COALESCE("unemployed_pop",0)           AS unemployed_pop,
        COALESCE("not_in_labor_force",0)       AS not_in_labor_force,
        COALESCE("group_quarters",0)           AS group_quarters,
        COALESCE("total_pop",0)                AS total_pop
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2017_5YR"
),

-- 2015 median income
tract15 AS (
    SELECT
        "geo_id",
        "median_income"                        AS median_income_2015
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2015_5YR"
),

-- 2018 median income
tract18 AS (
    SELECT
        "geo_id",
        "median_income"                        AS median_income_2018
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2018_5YR"
),

-- combine and compute income change
combined AS (
    SELECT
        t17."geo_id",
        t17.unemployed_pop,
        t17.not_in_labor_force,
        t17.group_quarters,
        t17.total_pop,
        t18.median_income_2018,
        t15.median_income_2015,
        (t18.median_income_2018 - t15.median_income_2015)  AS income_change
    FROM tract17 t17
    JOIN tract15 t15  ON t17."geo_id" = t15."geo_id"
    JOIN tract18 t18  ON t17."geo_id" = t18."geo_id"
    WHERE t18.median_income_2018 IS NOT NULL
      AND t15.median_income_2015 IS NOT NULL
),

-- create metrics per tract
metrics AS (
    SELECT
        SUBSTR("geo_id",1,2)                                   AS state_fips,
        GREATEST(unemployed_pop + not_in_labor_force - group_quarters,0) AS adjusted_non_labor,
        total_pop,
        income_change,
        CASE WHEN total_pop > 0
             THEN GREATEST(unemployed_pop + not_in_labor_force - group_quarters,0) / total_pop
        END                                                   AS proportion
    FROM combined
)

-- aggregate to state level and choose the 3 with the smallest totals
SELECT
    sf."postal_code"                                          AS state,
    SUM(m.income_change)                                      AS total_median_income_change_2015_2018,
    SUM(m.adjusted_non_labor)                                 AS total_adjusted_non_labor_force,
    AVG(m.proportion)                                         AS avg_population_adjusted_proportion
FROM metrics m
JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS" sf
      ON sf."fips"::TEXT = m.state_fips
GROUP BY sf."postal_code"
ORDER BY total_adjusted_non_labor_force ASC
LIMIT 3;
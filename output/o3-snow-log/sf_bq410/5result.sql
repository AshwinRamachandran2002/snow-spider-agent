WITH state_map AS (
    SELECT LPAD(CAST("fips" AS TEXT), 2, '0')  AS state_fips,
           "postal_code"
    FROM CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS
),
income_diff AS (
    /* median-income change between 2015 and 2018, tract (block-group) level */
    SELECT b15."geo_id",
           (b18."median_income" - b15."median_income") AS income_change
    FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2015_5YR b15
    JOIN  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR b18
          ON b15."geo_id" = b18."geo_id"
    WHERE b15."median_income" IS NOT NULL
      AND b18."median_income" IS NOT NULL
),
tract_nlf AS (
    /* adjusted non-labor-force (only “not_in_labor_force” available) */
    SELECT "geo_id",
           GREATEST(COALESCE("not_in_labor_force", 0), 0) AS adjusted_nlf,
           "total_pop"
    FROM   CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2017_5YR
),
combined AS (
    SELECT n."geo_id",
           n.adjusted_nlf,
           n."total_pop",
           d.income_change
    FROM   tract_nlf      n
    JOIN   income_diff    d  ON n."geo_id" = d."geo_id"
)
SELECT  sm."postal_code"                                           AS "state_abbreviation",
        SUM(c.income_change)                                       AS "total_median_income_change_2015_2018",
        SUM(c.adjusted_nlf)                                        AS "total_adjusted_non_labor_force",
        AVG(c.adjusted_nlf / NULLIF(c."total_pop", 0))             AS "avg_population_adjusted_proportion"
FROM    combined        c
JOIN    state_map       sm  ON SUBSTR(c."geo_id", 1, 2) = sm.state_fips
GROUP BY sm."postal_code"
ORDER BY "total_adjusted_non_labor_force" ASC
LIMIT 3;
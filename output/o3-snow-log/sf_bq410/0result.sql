WITH tract_2017 AS (        /* 2017 tract-level (block-group) values */
    SELECT
        "geo_id",
        SUBSTR("geo_id",1,2)                                 AS state_fips,
        /* unemployed_pop and group_quarters are unavailable, 
           so adjusted NLF reduces to the (clamped) NLF count */
        GREATEST(COALESCE("not_in_labor_force",0),0)         AS adjusted_non_labor_force,
        "total_pop",
        CASE 
            WHEN "total_pop" > 0 
            THEN GREATEST(COALESCE("not_in_labor_force",0),0) / "total_pop" 
        END                                                 AS adj_prop
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2017_5YR
), income_change AS (        /* tract-level median-income change 2015 → 2018 */
    SELECT
        t15."geo_id",
        t18."median_income" - t15."median_income"            AS income_diff
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2015_5YR t15
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR t18
          ON t15."geo_id" = t18."geo_id"
    WHERE t15."median_income" IS NOT NULL
      AND t18."median_income" IS NOT NULL
), merged AS (              /* keep tracts that have income-diff information */
    SELECT
        t."geo_id",
        t.state_fips,
        t.adjusted_non_labor_force,
        t."total_pop",
        t.adj_prop,
        ic.income_diff
    FROM tract_2017 t
    JOIN income_change ic
          ON t."geo_id" = ic."geo_id"
)
SELECT
    sf."postal_code"                                          AS state_abbreviation,
    SUM(merged.income_diff)                                   AS total_median_income_change,
    SUM(merged.adjusted_non_labor_force)                      AS total_adjusted_non_labor_force,
    AVG(merged.adj_prop)                                      AS avg_population_adjusted_proportion
FROM merged
JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS sf
      ON CAST(merged.state_fips AS INTEGER) = sf."fips"
GROUP BY sf."postal_code"
ORDER BY total_adjusted_non_labor_force ASC NULLS LAST
LIMIT 3;
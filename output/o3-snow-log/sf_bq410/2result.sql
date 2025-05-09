WITH income_diff AS (                   /* tract-level median-income change 2015 → 2018 */
    SELECT
        bg18."geo_id",
        bg18."median_income" - bg15."median_income"      AS income_change
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2015_5YR bg15
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR bg18
          ON bg18."geo_id" = bg15."geo_id"
    WHERE bg18."median_income" IS NOT NULL
      AND bg15."median_income" IS NOT NULL
),                                                /* ------------------------------ */
adj_non_labor AS (               /* 2017 adjusted non-labor-force & tract-level proportion */
    SELECT
        bg17."geo_id",
        bg17."total_pop",
        /* adjusted non-labor-force population (only not_in_labor_force available) */
        GREATEST(COALESCE(bg17."not_in_labor_force",0),0)                      AS adj_nlf,
        CASE WHEN bg17."total_pop" > 0
             THEN GREATEST(COALESCE(bg17."not_in_labor_force",0),0) / bg17."total_pop"
        END                                                                    AS adj_prop
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2017_5YR bg17
)
SELECT
    sf."postal_code"                                    AS state_abbr,
    SUM(id.income_change)                               AS total_median_income_change,
    SUM(anl.adj_nlf)                                    AS total_adjusted_non_labor_force,
    AVG(anl.adj_prop)                                   AS avg_population_adjusted_proportion
FROM income_diff           id
JOIN adj_non_labor         anl  ON id."geo_id" = anl."geo_id"
JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS sf
     ON TO_NUMBER(LEFT(id."geo_id",2)) = sf."fips"
GROUP BY sf."postal_code"
ORDER BY total_adjusted_non_labor_force ASC
FETCH FIRST 3 ROWS;
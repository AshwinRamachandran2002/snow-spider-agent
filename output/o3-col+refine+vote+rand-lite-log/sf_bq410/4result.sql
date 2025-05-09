WITH income_diff AS (   -- 1. per-tract median-income change 2015 ➜ 2018
    SELECT
        t17."geo_id",
        (t18."median_income" - t15."median_income") AS "income_change"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2017_5YR t17
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2015_5YR  t15
      ON t17."geo_id" = t15."geo_id"
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2018_5YR  t18
      ON t17."geo_id" = t18."geo_id"
    WHERE t15."median_income" IS NOT NULL
      AND t18."median_income" IS NOT NULL
),
tract_metrics AS (      -- 2. add 2017 adjusted non-labor-force figures
    SELECT
        t17."geo_id",
        GREATEST(
            0,
            COALESCE(t17."unemployed_pop",0)
          + COALESCE(t17."not_in_labor_force",0)
          - COALESCE(t17."group_quarters",0)
        )                                   AS "adj_non_labor",
        t17."total_pop",
        d."income_change"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2017_5YR t17
    JOIN income_diff d
      ON t17."geo_id" = d."geo_id"
),
state_metrics AS (      -- 3. aggregate to state level
    SELECT
        s."postal_code"                                         AS "state",
        SUM(tm."income_change")                                 AS "total_median_income_change",
        SUM(tm."adj_non_labor")                                 AS "total_adjusted_non_labor_force",
        AVG( tm."adj_non_labor" / NULLIF(tm."total_pop",0) )    AS "avg_population_adjusted_proportion"
    FROM tract_metrics tm
    JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS s
      ON TO_NUMBER(SUBSTR(tm."geo_id",1,2)) = s."fips"
    GROUP BY s."postal_code"
)
-- 4. final output – 3 states with the smallest adjusted non-labor-force totals
SELECT
    "state",
    "total_median_income_change",
    "total_adjusted_non_labor_force",
    "avg_population_adjusted_proportion"
FROM state_metrics
ORDER BY "total_adjusted_non_labor_force" ASC
LIMIT 3;
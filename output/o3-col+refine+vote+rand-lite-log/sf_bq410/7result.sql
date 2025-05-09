WITH
-- 1. 2017 tract-level adjusted non-labor force values
tract_adj AS (
    SELECT
        CAST(SUBSTR(t."geo_id",1,2) AS INT)                                                         AS "state_fips",
        GREATEST(
            0,
            COALESCE(t."unemployed_pop",0)
          + COALESCE(t."not_in_labor_force",0)
          - COALESCE(t."group_quarters",0)
        )                                                                                           AS "adj_non_labor",
        t."total_pop"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2017_5YR" t
),

-- 2. State-level aggregation of the adjusted non-labor metrics
state_adj AS (
    SELECT
        ta."state_fips",
        SUM(ta."adj_non_labor")                                                                     AS "total_adj_non_labor",
        AVG(CASE WHEN ta."total_pop" > 0
                 THEN ta."adj_non_labor" / ta."total_pop"
            END)                                                                                    AS "avg_adj_ratio"
    FROM tract_adj ta
    GROUP BY ta."state_fips"
),

-- 3. Median-income change 2015 → 2018 summed across tracts, by state
state_income_change AS (
    SELECT
        CAST(SUBSTR(a."geo_id",1,2) AS INT)                                                         AS "state_fips",
        SUM(b."median_income" - a."median_income")                                                  AS "total_income_change"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2015_5YR" a
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2018_5YR" b
          ON a."geo_id" = b."geo_id"
    WHERE a."median_income" IS NOT NULL
      AND b."median_income" IS NOT NULL
    GROUP BY CAST(SUBSTR(a."geo_id",1,2) AS INT)
)

-- 4. Combine metrics and return the three states with the smallest totals
SELECT
    sf."postal_code"                                                                                 AS "state_abbr",
    sic."total_income_change",
    sa."total_adj_non_labor",
    sa."avg_adj_ratio"
FROM state_income_change  sic
JOIN state_adj            sa  ON sic."state_fips" = sa."state_fips"
JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS" sf
     ON sic."state_fips" = sf."fips"
ORDER BY sa."total_adj_non_labor" ASC
LIMIT 3;
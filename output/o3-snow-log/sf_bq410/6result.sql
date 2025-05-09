WITH tract_level AS (      /* 1 ─ build tract-level metrics */
    SELECT
        t17."geo_id",
        t17."total_pop",
        /* adjusted non-labor-force for 2017
           (tables do not contain unemployed_pop or group_quarters ⇒ treat as 0) */
        GREATEST( COALESCE(t17."not_in_labor_force",0) , 0 )           AS adjusted_nlf_17,
        /* median-income change 2015 → 2018 */
        ( t18."median_income" - t15."median_income" )                  AS income_change,
        /* two–digit state FIPS from geo_id */
        TO_NUMBER(SUBSTR(t17."geo_id",1,2))                            AS state_fips
    FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2017_5YR  t17
    JOIN  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2015_5YR  t15
          ON t17."geo_id" = t15."geo_id"
    JOIN  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.BLOCKGROUP_2018_5YR  t18
          ON t17."geo_id" = t18."geo_id"
    WHERE t15."median_income" IS NOT NULL
      AND t18."median_income" IS NOT NULL
),

tract_with_state AS (      /* 2 ─ attach state abbreviation */
    SELECT
        s."postal_code"               AS state_abbrev,
        tl.adjusted_nlf_17,
        tl."total_pop"                AS total_pop,
        tl.income_change
    FROM tract_level tl
    JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS  s
          ON tl.state_fips = s."fips"
)

/* 3 ─ aggregate to state & return the 3 smallest adjusted NLF totals */
SELECT
    state_abbrev,
    SUM(income_change)                               AS total_median_income_change,
    SUM(adjusted_nlf_17)                             AS total_adjusted_non_labor_force,
    AVG(adjusted_nlf_17 / NULLIF(total_pop,0))       AS avg_population_adjusted_proportion
FROM tract_with_state
GROUP BY state_abbrev
ORDER BY total_adjusted_non_labor_force ASC NULLS LAST
LIMIT 3;
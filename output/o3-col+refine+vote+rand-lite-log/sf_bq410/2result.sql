SELECT
    s."postal_code"                                                           AS "state_abbr",
    SUM(t18."median_income" - t15."median_income")                            AS "total_median_income_change_2015_2018",
    SUM(
        CASE
            WHEN (COALESCE(t17."unemployed_pop",0) 
                  + COALESCE(t17."not_in_labor_force",0) 
                  - COALESCE(t17."group_quarters",0)) < 0
            THEN 0
            ELSE  (COALESCE(t17."unemployed_pop",0) 
                   + COALESCE(t17."not_in_labor_force",0) 
                   - COALESCE(t17."group_quarters",0))
        END
    )                                                                          AS "total_adjusted_non_labor_force_pop",
    AVG(
        CASE
            WHEN (COALESCE(t17."unemployed_pop",0) 
                  + COALESCE(t17."not_in_labor_force",0) 
                  - COALESCE(t17."group_quarters",0)) < 0
            THEN 0
            ELSE  (COALESCE(t17."unemployed_pop",0) 
                   + COALESCE(t17."not_in_labor_force",0) 
                   - COALESCE(t17."group_quarters",0))
        END
        / NULLIF(t17."total_pop",0)
    )                                                                          AS "avg_adjusted_nlf_proportion"
FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2017_5YR  t17
JOIN  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2015_5YR  t15
      ON t17."geo_id" = t15."geo_id"
JOIN  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.CENSUSTRACT_2018_5YR  t18
      ON t17."geo_id" = t18."geo_id"
JOIN  CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS                    s
      ON TO_NUMBER(SUBSTR(t17."geo_id",1,2)) = s."fips"
WHERE t18."median_income" IS NOT NULL
  AND t15."median_income" IS NOT NULL
GROUP BY s."postal_code"
ORDER BY "total_adjusted_non_labor_force_pop" ASC
LIMIT 3;
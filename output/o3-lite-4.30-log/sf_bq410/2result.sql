WITH tract_metrics AS (
    SELECT
        s."postal_code"                                                       AS state,
        GREATEST(
            0,
            COALESCE(t17."unemployed_pop",0) +
            COALESCE(t17."not_in_labor_force",0) -
            COALESCE(t17."group_quarters",0)
        )                                                                     AS adjusted_nlf,
        t17."total_pop",
        GREATEST(
            0,
            COALESCE(t17."unemployed_pop",0) +
            COALESCE(t17."not_in_labor_force",0) -
            COALESCE(t17."group_quarters",0)
        ) / NULLIF(t17."total_pop",0)                                          AS adjusted_ratio,
        (t18."median_income" - t15."median_income")                           AS income_change
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2017_5YR" t17
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2018_5YR" t18
      ON t17."geo_id" = t18."geo_id"
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2015_5YR" t15
      ON t17."geo_id" = t15."geo_id"
    JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS" s
      ON LPAD(s."fips",2,'0') = SUBSTR(t17."geo_id",1,2)
    WHERE t17."total_pop" > 0
      AND t18."median_income" IS NOT NULL
      AND t15."median_income" IS NOT NULL
)

SELECT
    state,
    ROUND(SUM(income_change), 4)                                   AS total_median_income_change,
    ROUND(SUM(adjusted_nlf), 4)                                    AS total_adjusted_non_labor_force_population,
    ROUND(AVG(adjusted_ratio), 4)                                  AS avg_adjusted_non_labor_force_ratio
FROM tract_metrics
GROUP BY state
ORDER BY total_adjusted_non_labor_force_population ASC
LIMIT 3;
WITH tract_metrics AS (
    SELECT
        /* derive state FIPS from first two digits of tract GEOID */
        TO_NUMBER(SUBSTR(t17."geo_id", 1, 2))                     AS "state_fips",
        
        /* adjusted non-labor force, clamped at zero */
        GREATEST(
            0,
            COALESCE(t17."unemployed_pop", 0)
          + COALESCE(t17."not_in_labor_force", 0)
          - COALESCE(t17."group_quarters", 0)
        )                                                         AS "adj_non_labor",
        
        /* tract population */
        t17."total_pop",
        
        /* 2015→2018 median-income change */
        (t18."median_income" - t15."median_income")               AS "income_change"
        
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2017_5YR" t17
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2015_5YR" t15
      ON t17."geo_id" = t15."geo_id"
    JOIN CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."CENSUSTRACT_2018_5YR" t18
      ON t17."geo_id" = t18."geo_id"
    WHERE t15."median_income" IS NOT NULL
      AND t18."median_income" IS NOT NULL
)

SELECT
    f."postal_code"                                              AS "state",
    SUM(m."income_change")                                       AS "total_income_change",
    SUM(m."adj_non_labor")                                       AS "state_adj_non_labor",
    AVG(m."adj_non_labor" / NULLIF(m."total_pop", 0))            AS "avg_prop"
FROM tract_metrics m
JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS" f
  ON m."state_fips" = f."fips"
GROUP BY f."postal_code"
ORDER BY "state_adj_non_labor" ASC
LIMIT 3;
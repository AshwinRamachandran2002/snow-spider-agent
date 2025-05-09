SELECT 
    f."state"                                            AS "state",
    ROUND(0.38 * s."employed_wholesale_trade", 0)        AS "vulnerable_wholesale_trade",
    ROUND(0.41 * s."employed_manufacturing", 0)          AS "vulnerable_manufacturing",
    ROUND(0.38 * s."employed_wholesale_trade" +
          0.41 * s."employed_manufacturing", 0)          AS "total_vulnerable_workers"
FROM "CENSUS_BUREAU_ACS_2"."CENSUS_BUREAU_ACS"."STATE_2017_1YR"  s
JOIN "CENSUS_BUREAU_ACS_2"."CYCLISTIC"."STATE_FIPS"              f
  ON TO_NUMBER(s."geo_id") = f."fips"
ORDER BY "total_vulnerable_workers" DESC NULLS LAST;
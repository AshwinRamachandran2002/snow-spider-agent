/*--------------------------------------------------------------------
  Compute “vulnerable” employment for every state:
      – vulnerable_wholesale_trade = 38% of 2017 wholesale-trade workers
      – vulnerable_manufacturing  = 41% of 2017 manufacturing workers
  Join 2017 ACS state-level file to the STATE_FIPS look-up so we can
  report readable state names.  Finally order states by the combined
  vulnerable-worker total (largest → smallest).
--------------------------------------------------------------------*/
SELECT
    sf."state"                                                     AS "state",
    s."employed_wholesale_trade" * 0.38                            AS "vulnerable_wholesale_trade",
    s."employed_manufacturing"  * 0.41                            AS "vulnerable_manufacturing",
    s."employed_wholesale_trade" * 0.38
  + s."employed_manufacturing"  * 0.41                            AS "total_vulnerable_workers"
FROM  CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS."STATE_2017_1YR"  s
JOIN  CENSUS_BUREAU_ACS_2.CYCLISTIC."STATE_FIPS"             sf
      ON TO_NUMBER(s."geo_id") = sf."fips"
ORDER BY
    "total_vulnerable_workers" DESC NULLS LAST;
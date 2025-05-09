/*--------------------------------------------------------------------
  Compute 2017 “vulnerable” workers by state.

  • vulnerable_wholesale_trade = 38 % of 2017 wholesale-trade jobs
  • vulnerable_manufacturing  = 41 % of 2017 manufacturing jobs
  • total_vulnerable_workers  = sum of the two

  Results are sorted in descending order of total vulnerable workers.
--------------------------------------------------------------------*/
WITH state_emp AS (
    SELECT
        TO_NUMBER("geo_id")                           AS state_fips,
        "employed_wholesale_trade",
        "employed_manufacturing"
    FROM CENSUS_BUREAU_ACS_2.CENSUS_BUREAU_ACS.STATE_2017_1YR
),
vulnerable AS (
    SELECT
        f."state",
        ROUND(e."employed_wholesale_trade" * 0.38, 0) AS vulnerable_wholesale_trade,
        ROUND(e."employed_manufacturing"   * 0.41, 0) AS vulnerable_manufacturing,
        ROUND(e."employed_wholesale_trade" * 0.38 +
              e."employed_manufacturing"   * 0.41, 0) AS total_vulnerable_workers
    FROM state_emp e
    JOIN CENSUS_BUREAU_ACS_2.CYCLISTIC.STATE_FIPS f
         ON f."fips" = e.state_fips
)
SELECT
    "state",
    vulnerable_wholesale_trade,
    vulnerable_manufacturing,
    total_vulnerable_workers
FROM vulnerable
ORDER BY total_vulnerable_workers DESC NULLS LAST;
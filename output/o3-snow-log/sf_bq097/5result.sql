SELECT
    "GeoName",
    MAX(CASE WHEN YEAR("Year") = 2012 THEN "Earnings_per_job_avg" END) AS "Earnings_2012",
    MAX(CASE WHEN YEAR("Year") = 2017 THEN "Earnings_per_job_avg" END) AS "Earnings_2017",
    MAX(CASE WHEN YEAR("Year") = 2017 THEN "Earnings_per_job_avg" END)
      - MAX(CASE WHEN YEAR("Year") = 2012 THEN "Earnings_per_job_avg" END)  AS "Increase_2012_to_2017"
FROM SDOH.SDOH_BEA_CAINC30.FIPS
WHERE "GeoName" LIKE '%, MA'          -- keep only Massachusetts regions
  AND YEAR("Year") IN (2012, 2017)    -- keep only the needed years
GROUP BY
    "GeoName"
ORDER BY
    "Increase_2012_to_2017" DESC NULLS LAST;
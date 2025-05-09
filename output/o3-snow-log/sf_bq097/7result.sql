SELECT
    "GeoName",
    MAX(CASE WHEN YEAR("Year") = 2017 THEN "Earnings_per_job_avg" END) 
      - MAX(CASE WHEN YEAR("Year") = 2012 THEN "Earnings_per_job_avg" END) 
      AS "Increase_2012_2017"
FROM SDOH.SDOH_BEA_CAINC30.FIPS
WHERE "GeoName" LIKE '% MA'                        -- only Massachusetts geographies
  AND YEAR("Year") IN (2012, 2017)                 -- restrict to the two years of interest
GROUP BY "GeoName"
HAVING COUNT(DISTINCT YEAR("Year")) = 2            -- keep rows that have both years’ data
ORDER BY "Increase_2012_2017" DESC NULLS LAST;     -- largest increases first
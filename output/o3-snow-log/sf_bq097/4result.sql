SELECT
    "GeoName",
    MAX(CASE WHEN "Year" = '2017-01-01' THEN "Earnings_per_job_avg" END) 
      - 
    MAX(CASE WHEN "Year" = '2012-01-01' THEN "Earnings_per_job_avg" END) 
      AS "Earnings_per_job_avg_increase"
FROM SDOH.SDOH_BEA_CAINC30.FIPS
WHERE "GeoName" LIKE '%, MA'                         -- only Massachusetts geographies
  AND "Year" IN ('2012-01-01','2017-01-01')          -- keep the two target years
GROUP BY "GeoName"
HAVING COUNT(DISTINCT "Year") = 2                    -- ensure both years are present
ORDER BY "Earnings_per_job_avg_increase" DESC NULLS LAST;
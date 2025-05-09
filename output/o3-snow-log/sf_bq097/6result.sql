/*  Increase in average earnings per job from 2012 to 2017  
    for every Massachusetts county (GeoName ends with 'MA')  */

SELECT
    "GeoName",
    MAX(CASE WHEN YEAR("Year") = 2012 THEN "Earnings_per_job_avg" END) AS "Earnings_2012",
    MAX(CASE WHEN YEAR("Year") = 2017 THEN "Earnings_per_job_avg" END) AS "Earnings_2017",
    MAX(CASE WHEN YEAR("Year") = 2017 THEN "Earnings_per_job_avg" END)
      - MAX(CASE WHEN YEAR("Year") = 2012 THEN "Earnings_per_job_avg" END)    AS "Earnings_increase"
FROM SDOH.SDOH_BEA_CAINC30.FIPS
WHERE "GeoName" LIKE '%, MA'
  AND "Year" IN ('2012-01-01'::DATE, '2017-01-01'::DATE)
GROUP BY "GeoName"
ORDER BY "Earnings_increase" DESC NULLS LAST;
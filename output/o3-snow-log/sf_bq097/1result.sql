SELECT
    "GeoName",
    AVG(CASE WHEN YEAR("Year") = 2017 THEN "Earnings_per_job_avg" END)  AS "Earnings_2017",
    AVG(CASE WHEN YEAR("Year") = 2012 THEN "Earnings_per_job_avg" END)  AS "Earnings_2012",
    AVG(CASE WHEN YEAR("Year") = 2017 THEN "Earnings_per_job_avg" END) -
    AVG(CASE WHEN YEAR("Year") = 2012 THEN "Earnings_per_job_avg" END)  AS "Earnings_Increase_2012_2017"
FROM SDOH.SDOH_BEA_CAINC30.FIPS
WHERE RIGHT("GeoName", 2) = 'MA'
  AND YEAR("Year") IN (2012, 2017)
GROUP BY "GeoName"
HAVING COUNT(DISTINCT YEAR("Year")) = 2
ORDER BY "Earnings_Increase_2012_2017" DESC NULLS LAST;
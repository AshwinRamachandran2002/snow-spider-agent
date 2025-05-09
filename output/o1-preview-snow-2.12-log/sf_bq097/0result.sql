SELECT 
    t2012."GeoName",
    ROUND(t2017."Earnings_per_job_avg" - t2012."Earnings_per_job_avg", 4) AS "Increase_in_Earnings_per_Job"
FROM
    (SELECT "GeoName", "Earnings_per_job_avg"
     FROM SDOH.SDOH_BEA_CAINC30.FIPS
     WHERE "Year" = '2012-01-01' AND "GeoName" LIKE '%MA') AS t2012
INNER JOIN
    (SELECT "GeoName", "Earnings_per_job_avg"
     FROM SDOH.SDOH_BEA_CAINC30.FIPS
     WHERE "Year" = '2017-01-01' AND "GeoName" LIKE '%MA') AS t2017
ON t2012."GeoName" = t2017."GeoName"
ORDER BY t2012."GeoName";
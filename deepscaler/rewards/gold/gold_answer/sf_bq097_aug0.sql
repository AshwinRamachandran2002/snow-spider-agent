-- Task: Using the "FIPS" table from the "SDOH_BEA_CAINC30" schema, calculate the increase in average earnings per job between 2012 and 2017 for each geographic region in Massachusetts. Regions are identified by "MA" at the end of the "GeoName" field. Compute the difference by subtracting the 2012 "Earnings_per_job_avg" from the 2017 "Earnings_per_job_avg", round the result to four decimal places, and display the "GeoName" along with the calculated increase. Order the results alphabetically by "GeoName".

SELECT 
    t2012."GeoName", 
    ROUND(t2017."Earnings_per_job_avg" - t2012."Earnings_per_job_avg", 4) AS "Increase_in_Earnings_per_Job"
FROM 
    "SDOH"."SDOH_BEA_CAINC30"."FIPS" AS t2012
INNER JOIN 
    "SDOH"."SDOH_BEA_CAINC30"."FIPS" AS t2017
    ON t2012."GeoFIPS" = t2017."GeoFIPS"
WHERE 
    t2012."Year" = '2012-01-01' 
    AND t2017."Year" = '2017-01-01' 
    AND t2012."GeoName" LIKE '%MA'
ORDER BY 
    t2012."GeoName";
-- Task: What is the average earnings per job in 2012 for each geographic region in Massachusetts (indicated by "MA" at the end of GeoName)?

SELECT 
    t2012."GeoName", 
    t2012."Earnings_per_job_avg"
FROM 
    "SDOH"."SDOH_BEA_CAINC30"."FIPS" AS t2012
WHERE 
    t2012."Year" = '2012-01-01' 
    AND t2012."GeoName" LIKE '%MA'
ORDER BY 
    t2012."GeoName";
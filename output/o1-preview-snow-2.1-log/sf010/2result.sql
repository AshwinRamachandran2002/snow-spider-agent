SELECT "DATE", 
       ROUND(SUM("VALUE") * 100, 4) AS "Cumulative_Percentage"
FROM "US_REAL_ESTATE"."CYBERSYN"."FHFA_MORTGAGE_PERFORMANCE_TIMESERIES"
WHERE "VARIABLE" IN (
    'Percent_90_to_180_Days_Past_Due_Date_All Mortgages',
    'Percent_in_Forbearance_All Mortgages',
    'Percent_in_the_Process_of_Foreclosure,_Bankruptcy,_or_Deed_in_Lieu_All Mortgages'
)
AND "GEO_ID" = 'geoId/06'
AND EXTRACT(YEAR FROM "DATE") = 2023
GROUP BY "DATE"
ORDER BY "DATE";
SELECT
    ts."DATE" AS "Date",
    ROUND(SUM(ts."VALUE") * 100, 4) AS "Cumulative_Percentage"
FROM "US_REAL_ESTATE"."CYBERSYN"."FHFA_MORTGAGE_PERFORMANCE_TIMESERIES" ts
WHERE
    ts."GEO_ID" = 'geoId/06' AND
    ts."DATE" >= '2023-01-01' AND ts."DATE" <= '2023-12-31' AND
    ts."VARIABLE" IN (
        'Percent_90_to_180_Days_Past_Due_Date_All Mortgages',
        'Percent_in_Forbearance_All Mortgages',
        'Percent_in_the_Process_of_Foreclosure,_Bankruptcy,_or_Deed_in_Lieu_All Mortgages'
    )
GROUP BY ts."DATE"
ORDER BY ts."DATE";
-- Cumulative ratio of mortgages near‑default in California (state GEO_ID = geoId/06) for each 2023 reporting date
SELECT
    "DATE",
    SUM("VALUE") AS "CUM_NEAR_DEFAULT_RATIO"
FROM "US_REAL_ESTATE"."CYBERSYN"."FHFA_MORTGAGE_PERFORMANCE_TIMESERIES"
WHERE "GEO_ID" = 'geoId/06'  -- California
  AND "DATE" BETWEEN '2023-01-01' AND '2023-12-31'
  AND "VARIABLE" IN (  -- three components of “near‑default”
        'Percent_90_to_180_Days_Past_Due_Date_All Mortgages',
        'Percent_in_Forbearance_All Mortgages',
        'Percent_in_the_Process_of_Foreclosure,_Bankruptcy,_or_Deed_in_Lieu_All Mortgages'
      )
GROUP BY "DATE"
ORDER BY "DATE";
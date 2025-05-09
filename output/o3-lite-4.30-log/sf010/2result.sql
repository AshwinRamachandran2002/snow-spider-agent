SELECT
    "DATE"                                   AS record_date,
    ROUND(SUM("VALUE"), 4)                   AS cumulative_near_default_ratio
FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES
WHERE "GEO_ID" = 'geoId/06'                      -- California
  AND "DATE" BETWEEN '2023-01-01' AND '2023-12-31'
  -- use statewide “All Mortgages” series for each status
  AND "VARIABLE" ILIKE '%All Mortgages'
  -- include the three near‑default statuses
  AND (
        "VARIABLE" ILIKE 'Percent_90_to_180_Days_Past_Due_Date_%'
     OR "VARIABLE" ILIKE 'Percent_in_Forbearance_%'
     OR "VARIABLE" ILIKE '%Foreclosure%'
     OR "VARIABLE" ILIKE '%Bankruptcy%'
     OR "VARIABLE" ILIKE '%Deed%'
      )
GROUP BY "DATE"
ORDER BY "DATE";
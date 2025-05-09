SELECT
    "DATE",
    SUM("VALUE") AS "CUMULATIVE_NEAR_DEFAULT_PERCENT"
FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES
WHERE "GEO_ID" = 'geoId/06'                    -- California
  AND "DATE" BETWEEN '2023-01-01' AND '2023-12-31'
  AND (
        "VARIABLE" ILIKE '%90_to_180_Days_Past_Due%'   -- 90-180 days past due
     OR "VARIABLE" ILIKE '%Forbearance%'               -- in forbearance
     OR "VARIABLE" ILIKE '%Foreclosure%'               -- foreclosure process
     OR "VARIABLE" ILIKE '%Bankruptcy%'                -- bankruptcy process
     OR "VARIABLE" ILIKE '%Deed%in%Lieu%'              -- deed-in-lieu process
      )
GROUP BY "DATE"
ORDER BY "DATE";
SELECT
    t."DATE",
    SUM(t."VALUE") AS "CUMULATIVE_NEAR_DEFAULT_RATIO_PERCENT"
FROM  US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES  t
JOIN  US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES  a
      ON t."VARIABLE" = a."VARIABLE"
WHERE t."GEO_ID" = 'geoId/06'                           -- California
  AND t."DATE" BETWEEN '2023-01-01' AND '2023-12-31'    -- calendar year 2023
  AND a."VARIABLE_GROUP" IN (                           -- near‑default statuses
        'Percent 90 to 180 Days Past Due Date',
        'Percent in Forbearance',
        'Percent in Foreclosure, Bankruptcy, or Deed-in-Lieu'
      )
GROUP BY t."DATE"
ORDER BY t."DATE";
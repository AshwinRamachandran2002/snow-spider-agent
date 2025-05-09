SELECT 
    t."DATE",
    SUM(t."VALUE") AS "CUMULATIVE_NEAR_DEFAULT_RATIO"
FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES  t
WHERE t."GEO_ID" = 'geoId/06'                                       -- California
  AND t."DATE" BETWEEN '2023-01-01' AND '2023-12-31'                -- calendar year 2023
  AND t."VARIABLE" IN (                                             -- variables indicating “near-default” status
        SELECT a."VARIABLE"
        FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES a
        WHERE     a."VARIABLE_GROUP" ILIKE '%90 to 180 Days Past Due%'
           OR     a."VARIABLE_GROUP" ILIKE '%Forbearance%'
           OR     a."VARIABLE_NAME"  ILIKE '%foreclosure%' 
           OR     a."VARIABLE_NAME"  ILIKE '%bankruptcy%' 
           OR     a."VARIABLE_NAME"  ILIKE '%deed%'
      )
GROUP BY t."DATE"
ORDER BY t."DATE";
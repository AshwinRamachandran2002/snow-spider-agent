SELECT
    t."DATE",
    SUM(t."VALUE") AS "CUMULATIVE_RATIO_NEAR_DEFAULT"
FROM US_REAL_ESTATE.CYBERSYN."FHFA_MORTGAGE_PERFORMANCE_TIMESERIES" AS t
JOIN US_REAL_ESTATE.CYBERSYN."FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES" AS a
      ON t."VARIABLE" = a."VARIABLE"
WHERE t."GEO_ID" = 'geoId/06'                        -- California
  AND YEAR(t."DATE") = 2023                          -- only 2023 observations
  AND (                                              -- near-default categories
        a."VARIABLE_GROUP" ILIKE '%90 to 180 Days Past Due%'
     OR a."VARIABLE_GROUP" ILIKE '%Forbearance%'
     OR a."VARIABLE_GROUP" ILIKE '%Foreclosure%'
     OR a."VARIABLE_GROUP" ILIKE '%Bankruptcy%'
     OR a."VARIABLE_GROUP" ILIKE '%Deed%'
      )
GROUP BY t."DATE"
ORDER BY t."DATE";
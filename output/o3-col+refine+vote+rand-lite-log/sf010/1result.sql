SELECT
    ts."DATE",
    SUM(ts."VALUE") AS "CUMULATIVE_NEAR_DEFAULT_RATIO"
FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES ts
JOIN US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES att
      ON ts."VARIABLE" = att."VARIABLE"
WHERE ts."GEO_ID" = 'geoId/06'                               -- California
  AND ts."DATE" BETWEEN '2023-01-01' AND '2023-12-31'        -- Calendar year 2023
  AND (
        att."VARIABLE_NAME" ILIKE '%90 to 180 Days Past Due Date%' OR
        att."VARIABLE_NAME" ILIKE '%Forbearance%'            OR
        att."VARIABLE_NAME" ILIKE '%Foreclosure%'            OR
        att."VARIABLE_NAME" ILIKE '%Bankruptcy%'             OR
        att."VARIABLE_NAME" ILIKE '%Deed in Lieu%'
      )
GROUP BY ts."DATE"
ORDER BY ts."DATE";
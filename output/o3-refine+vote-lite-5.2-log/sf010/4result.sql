SELECT
    TS."DATE",
    SUM(TS."VALUE") AS "CUMULATIVE_NEAR_DEFAULT_PERCENT"
FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES AS TS
JOIN US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES AS ATTR
      ON TS."VARIABLE" = ATTR."VARIABLE"
WHERE TS."GEO_ID" = 'geoId/06'                                     -- California
  AND TS."DATE" BETWEEN '2023-01-01' AND '2023-12-31'              -- only 2023
  AND (
        ATTR."VARIABLE_GROUP" IN ('Percent 90 to 180 Days Past Due Date',
                                  'Percent in Forbearance')
        OR ATTR."VARIABLE_GROUP" LIKE 'Percent in Foreclosure%'    -- captures foreclosure / bankruptcy / deed‑in‑lieu
      )
GROUP BY TS."DATE"
ORDER BY TS."DATE";
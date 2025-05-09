WITH near_default_vars AS (
    SELECT "VARIABLE"
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES
    WHERE "VARIABLE_GROUP" IN (
              'Percent 90 to 180 Days Past Due Date',
              'Percent in Forbearance'
          )
       OR "VARIABLE_GROUP" ILIKE 'Percent in Foreclosure%'
)

SELECT
       t."DATE",
       SUM(t."VALUE") AS "CUMULATIVE_NEAR_DEFAULT_RATIO_PERCENT"
FROM   US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES t
JOIN   near_default_vars v
  ON   t."VARIABLE" = v."VARIABLE"
WHERE  t."GEO_ID" = 'geoId/06'                       -- California
  AND  t."DATE" BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY t."DATE"
ORDER BY t."DATE";
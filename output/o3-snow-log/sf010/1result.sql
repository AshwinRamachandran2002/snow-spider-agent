WITH relevant_variables AS (
    SELECT DISTINCT "VARIABLE"
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES
    WHERE "VARIABLE_GROUP" ILIKE 'Percent 90 to 180 Days Past Due Date%'
       OR "VARIABLE_GROUP" ILIKE 'Percent in Forbearance%'
       OR "VARIABLE_GROUP" ILIKE 'Percent in Foreclosure%'
       OR "VARIABLE_GROUP" ILIKE 'Percent in Bankruptcy%'
       OR "VARIABLE_GROUP" ILIKE 'Percent in Deed%'      -- captures deed-in-lieu variants
)
SELECT
    ts."DATE",
    SUM(ts."VALUE") AS "CUMULATIVE_NEAR_DEFAULT_RATIO_PERCENT"
FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES ts
JOIN relevant_variables rv
  ON ts."VARIABLE" = rv."VARIABLE"
WHERE ts."GEO_ID" = 'geoId/06'                        -- California
  AND DATE_PART('YEAR', ts."DATE") = 2023
GROUP BY ts."DATE"
ORDER BY ts."DATE" ASC;
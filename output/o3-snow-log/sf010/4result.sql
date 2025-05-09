/*--------------------------------------------------------------------
  Cumulative “near–default” mortgage ratios for California (geoId/06)
  in 2023.  Near-default is defined as any loan that is
  • 90-180 days past-due
  • in forbearance
  • in foreclosure / bankruptcy / deed-in-lieu (any variable-group that
    contains those words)
--------------------------------------------------------------------*/
SELECT
    t."DATE",
    SUM(t."VALUE")           AS "CUMULATIVE_NEAR_DEFAULT_PERCENT"
FROM
    US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES t
JOIN
    US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES  a
      ON t."VARIABLE" = a."VARIABLE"
WHERE
    t."GEO_ID" = 'geoId/06'                                      -- California
    AND t."DATE" BETWEEN '2023-01-01' AND '2023-12-31'            -- calendar 2023
    AND (
           a."VARIABLE_GROUP" =  'Percent 90 to 180 Days Past Due Date'
        OR a."VARIABLE_GROUP" =  'Percent in Forbearance'
        OR a."VARIABLE_GROUP" ILIKE '%foreclosure%'
        OR a."VARIABLE_GROUP" ILIKE '%bankruptcy%'
        OR a."VARIABLE_GROUP" ILIKE '%deed%'                      -- deed-in-lieu
        )
GROUP BY
    t."DATE"
ORDER BY
    t."DATE";
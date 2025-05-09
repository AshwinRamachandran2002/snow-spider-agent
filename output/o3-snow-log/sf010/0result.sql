/*  Cumulative ratio of California mortgages that are “near default”
    (90-180 days past-due, in forbearance, or in foreclosure / bankruptcy /
    deed-in-lieu) for every 2023 observation.                         */

WITH relevant_vars AS (
    SELECT  "VARIABLE"
    FROM    US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES
    WHERE   "VARIABLE_GROUP" ILIKE 'Percent 90 to 180 Days Past Due Date%'  -- past-due
        OR  "VARIABLE_GROUP" ILIKE 'Percent in Forbearance%'                -- forbearance
        OR  "VARIABLE_GROUP" ILIKE '%Foreclosure%'                          -- foreclosure
        OR  "VARIABLE_GROUP" ILIKE '%Bankruptcy%'                           -- bankruptcy
        OR  "VARIABLE_GROUP" ILIKE '%Deed%Lieu%'                            -- deed-in-lieu
),
ca_status_values AS (
    SELECT  t."DATE",
            t."VALUE"
    FROM    US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES t
    WHERE   t."GEO_ID" = 'geoId/06'                          -- California
      AND   DATE_PART('year', t."DATE") = 2023
      AND   t."VARIABLE" IN (SELECT "VARIABLE" FROM relevant_vars)
)

SELECT  "DATE",
        SUM("VALUE") AS "CUMULATIVE_NEAR_DEFAULT_RATIO"
FROM    ca_status_values
GROUP BY "DATE"
ORDER BY "DATE";
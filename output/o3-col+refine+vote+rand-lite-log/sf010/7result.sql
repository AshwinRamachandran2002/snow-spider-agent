SELECT
    "DATE",
    SUM("VALUE") AS "CUMULATIVE_NEAR_DEFAULT_RATIO"
FROM
    US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES
WHERE
        "GEO_ID" = 'geoId/06'                                   -- California
    AND "DATE" BETWEEN '2023-01-01' AND '2023-12-31'             -- year 2023
    AND (
            "VARIABLE_NAME" ILIKE '%90 to 180 Days Past Due%'    -- delinquent loans
         OR "VARIABLE_NAME" ILIKE '%in Forbearance%'             -- loans in forbearance
         OR "VARIABLE_NAME" ILIKE '%Process of Foreclosure%'     -- foreclosure / bankruptcy / deed-in-lieu
        )
GROUP BY
    "DATE"
ORDER BY
    "DATE";
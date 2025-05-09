SELECT
    "DATE",
    SUM("VALUE") AS "CUMULATIVE_NEAR_DEFAULT_RATIO_PERCENT"
FROM
    US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES
WHERE
    "GEO_ID" = 'geoId/06'                                  -- California
    AND "DATE" BETWEEN '2023-01-01' AND '2023-12-31'       -- year-2023 only
    AND (
        "VARIABLE_NAME" ILIKE '%90 to 180 Days Past Due%'  -- serious delinquency
        OR "VARIABLE_NAME" ILIKE '%in Forbearance%'        -- forbearance
        OR "VARIABLE_NAME" ILIKE '%Foreclosure%'           -- foreclosure
        OR "VARIABLE_NAME" ILIKE '%Bankruptcy%'            -- bankruptcy
        OR "VARIABLE_NAME" ILIKE '%Deed in Lieu%'          -- deed-in-lieu
    )
GROUP BY
    "DATE"
ORDER BY
    "DATE";
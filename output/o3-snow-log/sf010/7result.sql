WITH near_default AS (
    SELECT
        t."DATE",
        t."VALUE"
    FROM
        US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES AS t
        JOIN US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES AS a
          ON t."VARIABLE" = a."VARIABLE"
    WHERE
        t."GEO_ID" = 'geoId/06'                                   -- California
        AND t."DATE" BETWEEN '2023-01-01' AND '2023-12-31'        -- year 2023
        AND (
                a."VARIABLE_GROUP" ILIKE 'Percent 90 to 180 Days Past Due Date%' OR
                a."VARIABLE_GROUP" ILIKE 'Percent in Forbearance%'               OR
                a."VARIABLE_GROUP" ILIKE 'Percent in Foreclosure%'               OR
                a."VARIABLE_GROUP" ILIKE 'Percent in Bankruptcy%'                OR
                a."VARIABLE_GROUP" ILIKE 'Percent in Deed%'
            )                                                     -- near-default categories
)
SELECT
    "DATE",
    SUM("VALUE") AS "CUMULATIVE_RATIO_PERCENT"
FROM
    near_default
GROUP BY
    "DATE"
ORDER BY
    "DATE";
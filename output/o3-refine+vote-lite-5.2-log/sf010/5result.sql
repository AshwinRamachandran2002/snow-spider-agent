SELECT
    t."DATE",
    SUM(t."VALUE") AS "CUMULATIVE_RATIO_PERCENT"
FROM
    "US_REAL_ESTATE"."CYBERSYN"."FHFA_MORTGAGE_PERFORMANCE_TIMESERIES" t
JOIN
    "US_REAL_ESTATE"."CYBERSYN"."FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES" a
        ON t."VARIABLE" = a."VARIABLE"
WHERE
        t."GEO_ID" = 'geoId/06'                      -- California
    AND t."DATE" BETWEEN '2023-01-01' AND '2023-12-31'
    AND t."UNIT" = 'Percent'                         -- keep only percent measures
    AND (
            a."VARIABLE_GROUP" = 'Percent 90 to 180 Days Past Due Date'
         OR a."VARIABLE_GROUP" = 'Percent in Forbearance'
         OR a."VARIABLE_GROUP" ILIKE 'Percent in Foreclosure%'   -- captures foreclosure / bankruptcy / deed‑in‑lieu group
        )
GROUP BY
    t."DATE"
ORDER BY
    t."DATE";
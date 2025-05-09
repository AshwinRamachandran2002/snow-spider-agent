/*  Cumulative share of California mortgages that are
    either (a) 90–180 days past-due, (b) in forbearance,
    (c) in foreclosure, (d) in bankruptcy, or (e) in a
    deed-in-lieu process, for every reporting date in 2023. */

WITH relevant AS (
    SELECT
        t."DATE",
        a."VARIABLE_GROUP",
        t."VALUE"
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES t
    JOIN US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES a
          ON t."VARIABLE" = a."VARIABLE"
    WHERE t."GEO_ID" = 'geoId/06'                              -- California
      AND EXTRACT(YEAR FROM t."DATE") = 2023                  -- calendar year 2023
      AND (
            a."VARIABLE_GROUP" ILIKE 'Percent 90 to 180 Days Past Due Date%' OR
            a."VARIABLE_GROUP" ILIKE 'Percent in Forbearance%'              OR
            a."VARIABLE_GROUP" ILIKE 'Percent in Foreclosure%'              OR
            a."VARIABLE_GROUP" ILIKE 'Percent in Bankruptcy%'               OR
            a."VARIABLE_GROUP" ILIKE 'Percent in Deed%Lieu%'                -- covers “Deed-in-Lieu”
          )
),
dedup AS (   -- occasionally the same variable-group is reported for several market segments; keep one value
    SELECT
        "DATE",
        "VARIABLE_GROUP",
        MAX("VALUE") AS "VALUE"     -- pick the largest reported share for that status on that date
    FROM relevant
    GROUP BY "DATE", "VARIABLE_GROUP"
)

SELECT
    "DATE",
    ROUND(SUM("VALUE"), 4) AS "CUMULATIVE_NEAR_DEFAULT_RATIO_PERCENT"
FROM dedup
GROUP BY "DATE"
ORDER BY "DATE";
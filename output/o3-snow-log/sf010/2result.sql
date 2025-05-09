WITH risk_variables AS (   -- variables that signal loans near default
    SELECT "VARIABLE"
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES
    WHERE     "VARIABLE_GROUP" = 'Percent 90 to 180 Days Past Due Date'
           OR "VARIABLE_GROUP" = 'Percent in Forbearance'
           OR "VARIABLE_GROUP" ILIKE '%Foreclosure%'
           OR "VARIABLE_GROUP" ILIKE '%Bankruptcy%'
           OR "VARIABLE_GROUP" ILIKE '%Deed%'          -- deed-in-lieu
),

risk_data AS (             -- 2023 California values for those variables
    SELECT
        "DATE",
        "VALUE"
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES
    WHERE "GEO_ID" = 'geoId/06'                         -- California
      AND "DATE" BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
      AND "VARIABLE" IN (SELECT "VARIABLE" FROM risk_variables)
      AND "VALUE" IS NOT NULL
)

-- cumulative near-default ratio per reporting date
SELECT
    "DATE",
    ROUND(SUM("VALUE"), 4) AS "CUMULATIVE_NEAR_DEFAULT_RATIO_PERCENT"
FROM risk_data
GROUP BY "DATE"
ORDER BY "DATE";
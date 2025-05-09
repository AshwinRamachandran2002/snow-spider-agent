WITH near_default_variables AS (
    -- Variables indicating mortgages that are 90–180 days past due,
    -- in forbearance, or in foreclosure / bankruptcy / deed-in-lieu
    SELECT DISTINCT "VARIABLE"
    FROM US_REAL_ESTATE.CYBERSYN."FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES"
    WHERE  "VARIABLE_NAME" ILIKE '%90%180%Past%Due%'
        OR "VARIABLE_NAME" ILIKE '%Forbearance%'
        OR "VARIABLE_NAME" ILIKE '%Foreclosure%'
        OR "VARIABLE_NAME" ILIKE '%Bankruptcy%'
        OR "VARIABLE_NAME" ILIKE '%Deed%Lieu%'
),

ca_2023_near_default AS (
    -- Pull 2023 observations for California (GEO_ID = geoId/06)
    SELECT
        "DATE",
        "VALUE"
    FROM US_REAL_ESTATE.CYBERSYN."FHFA_MORTGAGE_PERFORMANCE_TIMESERIES"
    WHERE "GEO_ID" = 'geoId/06'
      AND "DATE" BETWEEN '2023-01-01' AND '2023-12-31'
      AND "VARIABLE" IN (SELECT "VARIABLE" FROM near_default_variables)
)

-- Aggregate to cumulative near-default percentage per date
SELECT
    "DATE",
    SUM("VALUE") AS "CUMULATIVE_NEAR_DEFAULT_PERCENT"
FROM ca_2023_near_default
GROUP BY "DATE"
ORDER BY "DATE";
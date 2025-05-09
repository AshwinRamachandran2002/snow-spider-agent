WITH near_default_variables AS (
    SELECT
        "VARIABLE"
    FROM "US_REAL_ESTATE"."CYBERSYN"."FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES"
    WHERE "VARIABLE_GROUP" IN (
        'Percent 90 to 180 Days Past Due Date',
        'Percent in Forbearance',
        'Percent Undergoing Foreclosure / Bankruptcy / Deed-in-Lieu'
    )
),

ca_near_default AS (
    SELECT
        t."DATE",
        t."VALUE"
    FROM "US_REAL_ESTATE"."CYBERSYN"."FHFA_MORTGAGE_PERFORMANCE_TIMESERIES" t
    WHERE
        t."GEO_ID" = 'geoId/06'                                                -- California
        AND t."VARIABLE" IN (SELECT "VARIABLE" FROM near_default_variables)     -- relevant distress categories
        AND t."DATE" BETWEEN '2023-01-01' AND '2023-12-31'                      -- restrict to calendar‑year 2023
)

SELECT
    "DATE",
    SUM("VALUE") AS "CUMULATIVE_RATIO_PERCENT"
FROM ca_near_default
GROUP BY "DATE"
ORDER BY "DATE";
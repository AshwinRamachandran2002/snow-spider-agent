WITH CA_NEAR_DEFAULT AS (
    SELECT
        T."DATE",
        T."VALUE" AS "PCT_VALUE"
    FROM "US_REAL_ESTATE"."CYBERSYN"."FHFA_MORTGAGE_PERFORMANCE_TIMESERIES" T
    JOIN "US_REAL_ESTATE"."CYBERSYN"."FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES"  A
          ON T."VARIABLE" = A."VARIABLE"
    WHERE
          T."GEO_ID" = 'geoId/06'                        -- California
      AND YEAR(T."DATE") = 2023                          -- only calendar‑year 2023
      AND A."MARKET" = 'Other Conventional Market'       -- broadest consistently‑reported segment
      AND (                                             -- the required “near‑default” buckets
              A."VARIABLE_GROUP" =  'Percent 90 to 180 Days Past Due Date'
           OR A."VARIABLE_GROUP" =  'Percent in Forbearance'
           OR A."VARIABLE_GROUP" =  'Percent in Foreclosure'
           OR A."VARIABLE_GROUP" =  'Percent in Bankruptcy'
           OR A."VARIABLE_GROUP" =  'Percent in Deed-in-Lieu'
          )
)
SELECT
    "DATE",
    SUM("PCT_VALUE") AS "CUMULATIVE_NEAR_DEFAULT_RATIO_PERCENT"
FROM CA_NEAR_DEFAULT
GROUP BY "DATE"
ORDER BY "DATE";
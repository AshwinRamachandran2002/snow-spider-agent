SELECT
    "DATE",
    SUM("VALUE") AS "CUMULATIVE_RATIO_PERCENT"
FROM
    US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES
WHERE
    "GEO_ID" = 'geoId/06'                                          -- California
    AND "DATE" BETWEEN '2023-01-01' AND '2023-12-31'               -- calendar year 2023
    AND (
            "VARIABLE" ILIKE '%90_to_180_Days_Past_Due_Date%'      -- seriously delinquent
         OR "VARIABLE" ILIKE '%in_Forbearance%'                    -- in forbearance
         OR "VARIABLE" ILIKE '%in_Foreclosure%'                    -- in foreclosure
         OR "VARIABLE" ILIKE '%Bankruptcy%'                        -- in bankruptcy
         OR "VARIABLE" ILIKE '%Deed_in_Lieu%'                      -- deed‑in‑lieu
        )
GROUP BY
    "DATE"
ORDER BY
    "DATE" ASC;
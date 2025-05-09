/* Cumulative “near-default” mortgage ratios for California (GEO_ID = 'geoId/06')
   in calendar year 2023.  Near-default is defined as any loan that is
   (a) 90-180 days past due, (b) in forbearance, or
   (c) in foreclosure / bankruptcy / deed-in-lieu.                       */

SELECT
    "DATE",
    /* add together every relevant percentage for the same date */
    SUM("VALUE")            AS "CUMULATIVE_NEAR_DEFAULT_RATIO"
FROM
    US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES
WHERE
        "GEO_ID" = 'geoId/06'                       -- California
    AND "DATE"  >= '2023-01-01'
    AND "DATE"  <  '2024-01-01'
    /* pick the variables that represent “near-default” situations */
    AND (
            "VARIABLE" ILIKE 'Percent_90_to_180_Days_Past_Due_Date%'
         OR "VARIABLE" ILIKE 'Percent_in_Forbearance%'
         OR "VARIABLE" ILIKE 'Percent_in_Foreclosure%'
         OR "VARIABLE" ILIKE 'Percent_in_Bankruptcy%'
         OR "VARIABLE" ILIKE 'Percent_in_Deed%'          -- deed-in-lieu
        )
GROUP BY
    "DATE"
ORDER BY
    "DATE";
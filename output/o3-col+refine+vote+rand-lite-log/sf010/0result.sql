/* Cumulative “near-default” mortgage ratios for California (2023)
   – sums the three statewide (“All Mortgages”) components:
       • 90- to 180-days past due
       • In forbearance
       • In foreclosure / bankruptcy / deed-in-lieu
*/
WITH ca_components_2023 AS (
    SELECT
        "DATE",
        "VALUE"
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES
    WHERE "GEO_ID" = 'geoId/06'                          -- California
      AND "DATE" BETWEEN '2023-01-01' AND '2023-12-31'   -- calendar-year 2023
      AND "VARIABLE_NAME" IN (
            'Percent 90 to 180 Days Past Due Date - All Mortgages',
            'Percent in Forbearance - All Mortgages',
            'Percent in the Process of Foreclosure, Bankruptcy, or Deed in Lieu - All Mortgages'
      )
)
SELECT
    "DATE",
    SUM("VALUE") AS "CUM_NEAR_DEFAULT_RATIO"
FROM ca_components_2023
GROUP BY "DATE"
ORDER BY "DATE";
-- Cumulative “near‑default” mortgage ratios for California (geoId/06) during 2023
WITH interest_vars AS (   -- capture every FHFA variable that reflects a “near‑default” status
    SELECT DISTINCT "VARIABLE"
    FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES
    WHERE "VARIABLE_GROUP" IN (
          'Percent 90 to 180 Days Past Due Date',
          'Percent in Forbearance',
          'Percent in Foreclosure Process',
          'Percent in Bankruptcy',
          'Percent in Deed in Lieu Process'
    )
)

SELECT
       t."DATE",
       SUM(t."VALUE")      AS "CUMULATIVE_RATIO_NEAR_DEFAULT"   -- summed percentage for the date
FROM   US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES t
WHERE  t."GEO_ID" = 'geoId/06'                                  -- California
  AND  DATE_PART('year', t."DATE") = 2023                       -- only 2023 observations
  AND  t."VARIABLE" IN (SELECT "VARIABLE" FROM interest_vars)   -- keep only “near‑default” metrics
GROUP BY
       t."DATE"
ORDER BY
       t."DATE";
SELECT
    "DATE" AS record_date,
    ROUND(
          COALESCE(MAX(CASE WHEN "VARIABLE_NAME" = 'Percent 90 to 180 Days Past Due Date - All Mortgages' THEN "VALUE" END), 0)
        + COALESCE(MAX(CASE WHEN "VARIABLE_NAME" = 'Percent in Forbearance - All Mortgages' THEN "VALUE" END), 0)
        + COALESCE(MAX(CASE WHEN "VARIABLE_NAME" = 'Percent in the Process of Foreclosure, Bankruptcy, or Deed in Lieu - All Mortgages' THEN "VALUE" END), 0)
    , 4) AS cumulative_near_default_ratio
FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES
WHERE "GEO_ID" = 'geoId/06'  -- California
  AND "DATE" BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY "DATE"
ORDER BY "DATE";
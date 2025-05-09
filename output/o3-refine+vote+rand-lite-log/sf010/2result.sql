/*--------------------------------------------------------------------
  Cumulative “near‑default” mortgage ratios (percent of outstanding
  loans) in California for every 2023 observation date.
  Near‑default = loans that are
      • 90–180 days past due,
      • in forbearance, or
      • in foreclosure / bankruptcy / deed‑in‑lieu.
--------------------------------------------------------------------*/
SELECT
    ts."DATE",
    SUM(ts."VALUE") AS "CUMULATIVE_NEAR_DEFAULT_RATIO_PERCENT"
FROM US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_TIMESERIES ts
JOIN US_REAL_ESTATE.CYBERSYN.FHFA_MORTGAGE_PERFORMANCE_ATTRIBUTES attr
      ON ts."VARIABLE" = attr."VARIABLE"
WHERE ts."GEO_ID" = 'geoId/06'                       -- California
  AND ts."DATE" >= '2023-01-01'
  AND ts."DATE" <  '2024-01-01'
  AND (
        attr."VARIABLE_GROUP" = 'Percent 90 to 180 Days Past Due Date'
     OR attr."VARIABLE_GROUP" = 'Percent in Forbearance'
     OR attr."VARIABLE_GROUP" ILIKE '%Foreclosure%'
      )
GROUP BY ts."DATE"
ORDER BY ts."DATE";
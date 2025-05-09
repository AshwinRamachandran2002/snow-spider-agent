SELECT
  "CoC_Number",
  "CoC_Name",
  CAST(SUM(CASE WHEN "Count_Year" = 2012 THEN "Homeless_Veterans" END) AS INT) AS "Homeless_Veterans_2012",
  CAST(SUM(CASE WHEN "Count_Year" = 2018 THEN "Homeless_Veterans" END) AS INT) AS "Homeless_Veterans_2018",
  CAST(SUM(CASE WHEN "Count_Year" = 2018 THEN "Homeless_Veterans" END) - SUM(CASE WHEN "Count_Year" = 2012 THEN "Homeless_Veterans" END) AS INT) AS "Change_in_Homeless_Veterans"
FROM
  SDOH.SDOH_HUD_PIT_HOMELESSNESS.HUD_PIT_BY_COC
WHERE
  "CoC_Number" LIKE 'NY%'
  AND "Count_Year" IN (2012, 2018)
GROUP BY
  "CoC_Number",
  "CoC_Name"
ORDER BY
  "CoC_Number";
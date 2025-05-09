SELECT
  "CoC_Number",
  "CoC_Name",
  SUM(CASE WHEN "Count_Year" = 2012 THEN "Homeless_Veterans" ELSE 0 END) AS "Homeless_Veterans_2012",
  SUM(CASE WHEN "Count_Year" = 2018 THEN "Homeless_Veterans" ELSE 0 END) AS "Homeless_Veterans_2018",
  SUM(CASE WHEN "Count_Year" = 2018 THEN "Homeless_Veterans" ELSE 0 END) -
  SUM(CASE WHEN "Count_Year" = 2012 THEN "Homeless_Veterans" ELSE 0 END) AS "Change_in_Homeless_Veterans"
FROM SDOH.SDOH_HUD_PIT_HOMELESSNESS.HUD_PIT_BY_COC
WHERE "Count_Year" IN (2012, 2018)
  AND "CoC_Number" LIKE 'NY-%'
GROUP BY "CoC_Number", "CoC_Name"
ORDER BY "CoC_Number";
SELECT
    "CoC_Number",
    "CoC_Name",
    SUM(CASE WHEN "Count_Year" = 2012 THEN "Homeless_Veterans" END) AS "Homeless_Veterans_2012",
    SUM(CASE WHEN "Count_Year" = 2018 THEN "Homeless_Veterans" END) AS "Homeless_Veterans_2018",
    SUM(CASE WHEN "Count_Year" = 2018 THEN "Homeless_Veterans" END) 
      - SUM(CASE WHEN "Count_Year" = 2012 THEN "Homeless_Veterans" END) AS "Change_Homeless_Veterans_2012_to_2018"
FROM
    SDOH.SDOH_HUD_PIT_HOMELESSNESS.HUD_PIT_BY_COC
WHERE
    "CoC_Number" LIKE 'NY-%'
    AND "Count_Year" IN (2012, 2018)
GROUP BY
    "CoC_Number",
    "CoC_Name"
HAVING
    COUNT(DISTINCT "Count_Year") = 2   -- keeps only CoCs with data in both years
ORDER BY
    "CoC_Number";
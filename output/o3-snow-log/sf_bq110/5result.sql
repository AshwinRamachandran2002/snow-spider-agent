SELECT
    "CoC_Number",
    MAX("CoC_Name")                                         AS "CoC_Name",
    SUM(CASE WHEN "Count_Year" = 2012 THEN "Homeless_Veterans" END) AS "Homeless_Veterans_2012",
    SUM(CASE WHEN "Count_Year" = 2018 THEN "Homeless_Veterans" END) AS "Homeless_Veterans_2018",
    SUM(CASE WHEN "Count_Year" = 2018 THEN "Homeless_Veterans" END)
      - SUM(CASE WHEN "Count_Year" = 2012 THEN "Homeless_Veterans" END) AS "Change_In_Homeless_Veterans"
FROM
    SDOH.SDOH_HUD_PIT_HOMELESSNESS.HUD_PIT_BY_COC
WHERE
    "CoC_Number" LIKE 'NY-%'              -- New York CoC regions
    AND "Count_Year" IN (2012, 2018)      -- only the two years of interest
GROUP BY
    "CoC_Number"
HAVING
    COUNT(DISTINCT "Count_Year") = 2      -- ensure data exists for both years
ORDER BY
    "CoC_Number";
WITH ny AS (
    SELECT 
        "CoC_Number",
        "CoC_Name",
        "Count_Year",
        "Homeless_Veterans"
    FROM SDOH.SDOH_HUD_PIT_HOMELESSNESS."HUD_PIT_BY_COC"
    WHERE "CoC_Number" LIKE 'NY-%'
      AND "Count_Year" IN (2012, 2018)
), 
agg AS (
    SELECT
        "CoC_Number",
        MAX("CoC_Name") AS "CoC_Name",
        SUM(CASE WHEN "Count_Year" = 2012 THEN "Homeless_Veterans" END) AS "Homeless_Veterans_2012",
        SUM(CASE WHEN "Count_Year" = 2018 THEN "Homeless_Veterans" END) AS "Homeless_Veterans_2018"
    FROM ny
    GROUP BY "CoC_Number"
)
SELECT
    "CoC_Number",
    "CoC_Name",
    "Homeless_Veterans_2012",
    "Homeless_Veterans_2018",
    "Homeless_Veterans_2018" - "Homeless_Veterans_2012" AS "Change_Homeless_Veterans"
FROM agg
WHERE "Homeless_Veterans_2012" IS NOT NULL
  AND "Homeless_Veterans_2018" IS NOT NULL
ORDER BY "CoC_Number";
SELECT
  state_counts."State_Abbreviation"
FROM (
  SELECT
    LEFT("CoC_Number", 2) AS "State_Abbreviation",
    SUM(CASE WHEN "Count_Year" = 2015 THEN "Unsheltered_Homeless_Individuals" END) AS "Unsheltered_2015",
    SUM(CASE WHEN "Count_Year" = 2018 THEN "Unsheltered_Homeless_Individuals" END) AS "Unsheltered_2018",
    ROUND(((SUM(CASE WHEN "Count_Year" = 2018 THEN "Unsheltered_Homeless_Individuals" END) - SUM(CASE WHEN "Count_Year" = 2015 THEN "Unsheltered_Homeless_Individuals" END)) / NULLIF(SUM(CASE WHEN "Count_Year" = 2015 THEN "Unsheltered_Homeless_Individuals" END), 0)) * 100, 4) AS "Percentage_Change"
  FROM "SDOH"."SDOH_HUD_PIT_HOMELESSNESS"."HUD_PIT_BY_COC"
  WHERE "Count_Year" IN (2015, 2018)
  GROUP BY "State_Abbreviation"
) AS state_counts
WHERE state_counts."Unsheltered_2015" IS NOT NULL AND state_counts."Unsheltered_2018" IS NOT NULL
ORDER BY ABS("Percentage_Change" - (
  SELECT ROUND(((national_counts."Unsheltered_2018" - national_counts."Unsheltered_2015") / national_counts."Unsheltered_2015") * 100, 4)
  FROM (
    SELECT
      SUM(CASE WHEN "Count_Year" = 2015 THEN "Unsheltered_Homeless_Individuals" END) AS "Unsheltered_2015",
      SUM(CASE WHEN "Count_Year" = 2018 THEN "Unsheltered_Homeless_Individuals" END) AS "Unsheltered_2018"
    FROM "SDOH"."SDOH_HUD_PIT_HOMELESSNESS"."HUD_PIT_BY_COC"
    WHERE "Count_Year" IN (2015, 2018)
  ) AS national_counts
)) ASC
LIMIT 5;
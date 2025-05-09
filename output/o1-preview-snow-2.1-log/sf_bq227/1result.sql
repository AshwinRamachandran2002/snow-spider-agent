WITH
  total_crimes_per_year AS (
    SELECT
      "year",
      SUM("value") AS total_crimes_year
    FROM LONDON.LONDON_CRIME.CRIME_BY_LSOA
    GROUP BY "year"
  ),
  category_crimes_per_year AS (
    SELECT
      "year",
      SUM(CASE WHEN "minor_category" = 'Other Theft' THEN "value" ELSE 0 END) AS "Other_Theft_Crimes",
      SUM(CASE WHEN "minor_category" = 'Theft From Motor Vehicle' THEN "value" ELSE 0 END) AS "Theft_From_Motor_Vehicle_Crimes",
      SUM(CASE WHEN "minor_category" = 'Possession Of Drugs' THEN "value" ELSE 0 END) AS "Possession_Of_Drugs_Crimes",
      SUM(CASE WHEN "minor_category" = 'Burglary in a Dwelling' THEN "value" ELSE 0 END) AS "Burglary_in_a_Dwelling_Crimes",
      SUM(CASE WHEN "minor_category" = 'Assault with Injury' THEN "value" ELSE 0 END) AS "Assault_with_Injury_Crimes"
    FROM LONDON.LONDON_CRIME.CRIME_BY_LSOA
    GROUP BY "year"
  )
SELECT
  t."year",
  ROUND(100.0 * COALESCE(c."Other_Theft_Crimes", 0) / t.total_crimes_year, 4) AS "Other_Theft_Percentage",
  ROUND(100.0 * COALESCE(c."Theft_From_Motor_Vehicle_Crimes", 0) / t.total_crimes_year, 4) AS "Theft_From_Motor_Vehicle_Percentage",
  ROUND(100.0 * COALESCE(c."Possession_Of_Drugs_Crimes", 0) / t.total_crimes_year, 4) AS "Possession_Of_Drugs_Percentage",
  ROUND(100.0 * COALESCE(c."Burglary_in_a_Dwelling_Crimes", 0) / t.total_crimes_year, 4) AS "Burglary_in_a_Dwelling_Percentage",
  ROUND(100.0 * COALESCE(c."Assault_with_Injury_Crimes", 0) / t.total_crimes_year, 4) AS "Assault_with_Injury_Percentage"
FROM
  total_crimes_per_year t
  LEFT JOIN category_crimes_per_year c ON t."year" = c."year"
ORDER BY
  t."year" ASC;
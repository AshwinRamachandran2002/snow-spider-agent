WITH
  top_5_minor_categories AS (
    SELECT `minor_category`
    FROM (
      SELECT `minor_category`, SUM(`value`) AS total_crimes
      FROM `bigquery-public-data.london_crime.crime_by_lsoa`
      WHERE `year` = 2008
      GROUP BY `minor_category`
      ORDER BY total_crimes DESC
      LIMIT 5
    )
  ),
  total_crimes_per_year AS (
    SELECT
      `year`,
      SUM(`value`) AS total_crimes
    FROM
      `bigquery-public-data.london_crime.crime_by_lsoa`
    GROUP BY `year`
  ),
  category_totals_per_year AS (
    SELECT
      `year`,
      `minor_category`,
      SUM(`value`) AS category_total
    FROM
      `bigquery-public-data.london_crime.crime_by_lsoa`
    WHERE
      `minor_category` IN (SELECT `minor_category` FROM top_5_minor_categories)
    GROUP BY `year`, `minor_category`
  )
SELECT
  c.`year` AS Year,
  ROUND(SUM(IF(c.`minor_category` = 'Theft From Motor Vehicle', c.`category_total`, 0)) * 100 / t.`total_crimes`, 4) AS Theft_From_Motor_Vehicle_Percentage,
  ROUND(SUM(IF(c.`minor_category` = 'Other Theft', c.`category_total`, 0)) * 100 / t.`total_crimes`, 4) AS Other_Theft_Percentage,
  ROUND(SUM(IF(c.`minor_category` = 'Possession Of Drugs', c.`category_total`, 0)) * 100 / t.`total_crimes`, 4) AS Possession_Of_Drugs_Percentage,
  ROUND(SUM(IF(c.`minor_category` = 'Burglary in a Dwelling', c.`category_total`, 0)) * 100 / t.`total_crimes`, 4) AS Burglary_in_a_Dwelling_Percentage,
  ROUND(SUM(IF(c.`minor_category` = 'Assault with Injury', c.`category_total`, 0)) * 100 / t.`total_crimes`, 4) AS Assault_with_Injury_Percentage
FROM
  category_totals_per_year c
JOIN
  total_crimes_per_year t ON c.`year` = t.`year`
GROUP BY
  c.`year`, t.`total_crimes`
ORDER BY
  c.`year` ASC;
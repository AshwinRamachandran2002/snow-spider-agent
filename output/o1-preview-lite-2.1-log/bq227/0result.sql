WITH
  total_crimes_per_year AS (
    SELECT
      year,
      SUM(value) AS total_crimes
    FROM
      `bigquery-public-data.london_crime.crime_by_lsoa`
    WHERE
      year >= 2008
    GROUP BY
      year
  ),
  specified_categories AS (
    SELECT DISTINCT minor_category
    FROM `bigquery-public-data.london_crime.crime_by_lsoa`
    WHERE minor_category IN ('Theft From Motor Vehicle', 'Other Theft', 'Common Assault', 'Burglary in a Dwelling', 'Criminal Damage To Motor Vehicle')
  ),
  crimes_per_year_category AS (
    SELECT
      c.year,
      c.minor_category,
      SUM(c.value) AS category_total
    FROM
      `bigquery-public-data.london_crime.crime_by_lsoa` c
    JOIN
      specified_categories s
    ON
      c.minor_category = s.minor_category
    WHERE
      c.year >= 2008
    GROUP BY
      c.year,
      c.minor_category
  ),
  percentage_table AS (
    SELECT
      c.year,
      c.minor_category,
      ROUND((c.category_total * 100.0) / t.total_crimes, 4) AS percentage_share
    FROM
      crimes_per_year_category c
    JOIN
      total_crimes_per_year t
    ON
      c.year = t.year
  )
SELECT
  year,
  MAX(CASE WHEN minor_category = 'Theft From Motor Vehicle' THEN percentage_share END) AS Theft_From_Motor_Vehicle_Percentage,
  MAX(CASE WHEN minor_category = 'Other Theft' THEN percentage_share END) AS Other_Theft_Percentage,
  MAX(CASE WHEN minor_category = 'Common Assault' THEN percentage_share END) AS Common_Assault_Percentage,
  MAX(CASE WHEN minor_category = 'Burglary in a Dwelling' THEN percentage_share END) AS Burglary_in_a_Dwelling_Percentage,
  MAX(CASE WHEN minor_category = 'Criminal Damage To Motor Vehicle' THEN percentage_share END) AS Criminal_Damage_To_Motor_Vehicle_Percentage
FROM
  percentage_table
GROUP BY
  year
ORDER BY
  year;
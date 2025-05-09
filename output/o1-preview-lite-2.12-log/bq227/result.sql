SELECT
  year AS Year,
  ROUND(SUM(CASE WHEN minor_category = 'Theft From Motor Vehicle' THEN value ELSE 0 END) / SUM(value) * 100, 4) AS Theft_From_Motor_Vehicle_Percent,
  ROUND(SUM(CASE WHEN minor_category = 'Other Theft' THEN value ELSE 0 END) / SUM(value) * 100, 4) AS Other_Theft_Percent,
  ROUND(SUM(CASE WHEN minor_category = 'Common Assault' THEN value ELSE 0 END) / SUM(value) * 100, 4) AS Common_Assault_Percent,
  ROUND(SUM(CASE WHEN minor_category = 'Burglary in a Dwelling' THEN value ELSE 0 END) / SUM(value) * 100, 4) AS Burglary_in_a_Dwelling_Percent,
  ROUND(SUM(CASE WHEN minor_category = 'Criminal Damage To Motor Vehicle' THEN value ELSE 0 END) / SUM(value) * 100, 4) AS Criminal_Damage_To_Motor_Vehicle_Percent
FROM
  `bigquery-public-data.london_crime.crime_by_lsoa`
WHERE
  year >= 2008
GROUP BY
  year
ORDER BY
  year;
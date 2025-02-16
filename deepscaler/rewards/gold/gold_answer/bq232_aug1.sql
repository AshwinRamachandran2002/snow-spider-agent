-- Task: Could you provide the total number of incidents within the 'Theft and Handling' category for each year in the Westminster borough?
SELECT
  year,
  SUM(value) AS Total_Incidents
FROM
  `bigquery-public-data.london_crime.crime_by_lsoa`
WHERE
  borough = 'Westminster'
  AND major_category = 'Theft and Handling'
GROUP BY
  year
ORDER BY
  year;
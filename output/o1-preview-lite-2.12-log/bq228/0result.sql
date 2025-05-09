SELECT major_category AS Major_Category, SUM(value) AS Number_of_Incidents
FROM `bigquery-public-data.london_crime.crime_by_lsoa`
WHERE borough = 'Barking and Dagenham' AND major_category IS NOT NULL AND value IS NOT NULL
GROUP BY Major_Category
ORDER BY Number_of_Incidents DESC
LIMIT 3;
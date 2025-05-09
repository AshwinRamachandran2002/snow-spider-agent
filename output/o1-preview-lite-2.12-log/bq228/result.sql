SELECT major_category, SUM(value) AS Number_of_Incidents
FROM `bigquery-public-data.london_crime.crime_by_lsoa`
WHERE borough = 'Barking and Dagenham'
GROUP BY major_category
ORDER BY Number_of_Incidents DESC
LIMIT 3;
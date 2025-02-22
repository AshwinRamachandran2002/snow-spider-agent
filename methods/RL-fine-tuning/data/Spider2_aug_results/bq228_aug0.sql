-- Task: List the top three major crime categories in the borough of Barking and Dagenham, along with the total number of incidents in each category (calculated by summing the 'value' field), ordered by the total number of incidents in descending order.
SELECT major_category, SUM(value) AS Number_of_Incidents
FROM `bigquery-public-data.london_crime.crime_by_lsoa`
WHERE borough = 'Barking and Dagenham'
GROUP BY major_category
ORDER BY Number_of_Incidents DESC
LIMIT 3;
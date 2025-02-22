-- Task: Provide a list of the number of incidents for each major crime category in the borough of Barking and Dagenham.
SELECT major_category, SUM(value) AS Number_of_Incidents
FROM `bigquery-public-data.london_crime.crime_by_lsoa`
WHERE borough = 'Barking and Dagenham'
GROUP BY major_category;
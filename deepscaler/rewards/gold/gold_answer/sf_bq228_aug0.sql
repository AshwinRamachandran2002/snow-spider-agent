-- Task: Please provide a list of the top three major crime categories in the borough of Barking and Dagenham, along with the total number of incidents in each category across all recorded data, ranked in descending order by the number of incidents.
SELECT "major_category", SUM("value") AS "Number_of_incidents"
FROM LONDON.LONDON_CRIME.CRIME_BY_LSOA
WHERE "borough" = 'Barking and Dagenham'
GROUP BY "major_category"
ORDER BY "Number_of_incidents" DESC NULLS LAST
LIMIT 3;
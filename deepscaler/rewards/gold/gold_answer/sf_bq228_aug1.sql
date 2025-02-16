-- Task: Provide the total number of criminal incidents in the borough of Barking and Dagenham.
SELECT SUM("value") AS "Total_incidents"
FROM LONDON.LONDON_CRIME.CRIME_BY_LSOA
WHERE "borough" = 'Barking and Dagenham';
SELECT "year" AS "Year", SUM("value") AS "Total_Incidents"
FROM LONDON.LONDON_CRIME.CRIME_BY_LSOA
WHERE "borough" = 'Westminster'
  AND "major_category" = 'Theft and Handling'
  AND "minor_category" = 'Other Theft'
GROUP BY "year"
ORDER BY "year";
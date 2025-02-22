-- Task: Provide the total number of 'Other Theft' incidents (with "value" greater than 0) within the 'Theft and Handling' major category for each year in the 'Westminster' borough, grouped and ordered by year.
SELECT "year", SUM("value") AS "Total_Incidents"
FROM "LONDON"."LONDON_CRIME"."CRIME_BY_LSOA"
WHERE "borough" = 'Westminster'
  AND "major_category" = 'Theft and Handling'
  AND "minor_category" = 'Other Theft'
  AND "value" > 0
GROUP BY "year"
ORDER BY "year";
SELECT "year", SUM("value") AS "Total_Incidents"
FROM "LONDON"."LONDON_CRIME"."CRIME_BY_LSOA"
WHERE "borough" = 'Westminster'
  AND "major_category" = 'Theft and Handling'
  AND "minor_category" = 'Other Theft'
  AND "value" > 0
GROUP BY "year"
ORDER BY "year";
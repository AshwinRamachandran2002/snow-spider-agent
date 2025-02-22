-- Task: Could you provide the total number of incidents within the 'Theft and Handling' category for each year in the Westminster borough?
SELECT "year", SUM("value") AS "Total_Incidents"
FROM "LONDON"."LONDON_CRIME"."CRIME_BY_LSOA"
WHERE "borough" = 'Westminster'
  AND "major_category" = 'Theft and Handling'
  AND "value" > 0
GROUP BY "year"
ORDER BY "year";
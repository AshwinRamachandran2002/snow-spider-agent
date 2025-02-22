-- Task: List all dates after January on which more than 10 sightings of Sterna paradisaea were recorded north of 40 degrees latitude.

SELECT "year", "month", "day"
FROM "GBIF"."GBIF"."OCCURRENCES"
WHERE "species" = 'Sterna paradisaea'
  AND "decimallatitude" > 40
  AND "month" > 1
GROUP BY "year", "month", "day"
HAVING COUNT(*) > 10
ORDER BY "month" ASC, "day" ASC, "year" ASC;
-- Task: Identify the year with the earliest date after January (starting from February 1st) on which more than 10 sightings of the species 'Sterna paradisaea' were recorded north of 40 degrees latitude. For each year, find the earliest date (by month and day) after January with over 10 sightings of this species in that region, then determine which year among them has the overall earliest such date.
SELECT "year"
FROM "GBIF"."GBIF"."OCCURRENCES"
WHERE "species" = 'Sterna paradisaea' AND "decimallatitude" > 40 AND "month" > 1
GROUP BY "year", "month", "day"
HAVING COUNT(*) > 10
ORDER BY "month" ASC, "day" ASC, "year" ASC
LIMIT 1;
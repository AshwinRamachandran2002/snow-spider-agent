SELECT "year"
FROM "GBIF"."GBIF"."OCCURRENCES"
WHERE "species" = 'Sterna paradisaea' AND "decimallatitude" > 40 AND "month" > 1
GROUP BY "year", "month", "day"
HAVING COUNT(*) > 10
ORDER BY "month" ASC, "day" ASC, "year" ASC
LIMIT 1;
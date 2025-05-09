SELECT sub."year"
FROM (
    SELECT "year", "month", "day", COUNT(*) AS "sighting_count"
    FROM GBIF.GBIF.OCCURRENCES
    WHERE "species" = 'Sterna paradisaea' AND "decimallatitude" > 40 AND "month" > 1
    GROUP BY "year", "month", "day"
    HAVING COUNT(*) > 10
) AS sub
ORDER BY sub."month" ASC, sub."day" ASC
LIMIT 1;
SELECT DISTINCT d."full_name"
FROM "F1"."F1"."DRIVERS" d
JOIN (
    SELECT r."driver_id", ra."year",
        COUNT(DISTINCT ra."round") AS "race_count",
        MIN(ra."round") AS "first_round",
        MAX(ra."round") AS "last_round"
    FROM "F1"."F1"."RESULTS" r
    JOIN "F1"."F1"."RACES" ra ON r."race_id" = ra."race_id"
    WHERE ra."year" BETWEEN 1950 AND 1959
    GROUP BY r."driver_id", ra."year"
) dr ON d."driver_id" = dr."driver_id"
JOIN "F1"."F1"."RESULTS" r_first ON dr."driver_id" = r_first."driver_id"
JOIN "F1"."F1"."RACES" ra_first ON r_first."race_id" = ra_first."race_id"
  AND ra_first."year" = dr."year" AND ra_first."round" = dr."first_round"
JOIN "F1"."F1"."RESULTS" r_last ON dr."driver_id" = r_last."driver_id"
JOIN "F1"."F1"."RACES" ra_last ON r_last."race_id" = ra_last."race_id"
  AND ra_last."year" = dr."year" AND ra_last."round" = dr."last_round"
WHERE dr."race_count" >= 2
  AND r_first."constructor_id" = r_last."constructor_id";
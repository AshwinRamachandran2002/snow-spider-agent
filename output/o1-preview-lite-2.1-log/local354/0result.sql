SELECT DISTINCT d."full_name", seasons."year", c_first."name" AS "constructor"
FROM
(
  SELECT r."driver_id", ra."year",
    MIN(ra."round") AS "first_round",
    MAX(ra."round") AS "last_round",
    COUNT(DISTINCT ra."race_id") AS "race_count"
  FROM "results" r
  JOIN "races" ra ON r."race_id" = ra."race_id"
  WHERE ra."year" BETWEEN 1950 AND 1959
  GROUP BY r."driver_id", ra."year"
  HAVING COUNT(DISTINCT ra."race_id") >= 2
) AS seasons
JOIN "drivers" d ON seasons."driver_id" = d."driver_id"
JOIN "results" r_first ON seasons."driver_id" = r_first."driver_id"
JOIN "races" ra_first ON r_first."race_id" = ra_first."race_id"
JOIN "constructors" c_first ON r_first."constructor_id" = c_first."constructor_id"
JOIN "results" r_last ON seasons."driver_id" = r_last."driver_id"
JOIN "races" ra_last ON r_last."race_id" = ra_last."race_id"
JOIN "constructors" c_last ON r_last."constructor_id" = c_last."constructor_id"
WHERE ra_first."year" = seasons."year"
  AND ra_last."year" = seasons."year"
  AND ra_first."round" = seasons."first_round"
  AND ra_last."round" = seasons."last_round"
  AND c_first."constructor_id" = c_last."constructor_id"
ORDER BY d."full_name", seasons."year";
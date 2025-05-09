SELECT DISTINCT d."full_name"
FROM
(
    SELECT r."driver_id", ra."year", MIN(ra."date") AS "first_race_date", MAX(ra."date") AS "last_race_date",
           COUNT(DISTINCT ra."race_id") AS "race_count"
    FROM "results" r
    JOIN "races" ra ON r."race_id" = ra."race_id"
    WHERE ra."year" BETWEEN 1950 AND 1959
    GROUP BY r."driver_id", ra."year"
    HAVING COUNT(DISTINCT ra."race_id") >= 2
) s
JOIN "results" r_first ON s."driver_id" = r_first."driver_id"
    AND r_first."race_id" = (
        SELECT r_sub."race_id"
        FROM "results" r_sub
        JOIN "races" ra_sub ON r_sub."race_id" = ra_sub."race_id"
        WHERE r_sub."driver_id" = s."driver_id"
          AND ra_sub."year" = s."year"
          AND ra_sub."date" = s."first_race_date"
        LIMIT 1
    )
JOIN "constructors" c_first ON r_first."constructor_id" = c_first."constructor_id"
JOIN "results" r_last ON s."driver_id" = r_last."driver_id"
    AND r_last."race_id" = (
        SELECT r_sub."race_id"
        FROM "results" r_sub
        JOIN "races" ra_sub ON r_sub."race_id" = ra_sub."race_id"
        WHERE r_sub."driver_id" = s."driver_id"
          AND ra_sub."year" = s."year"
          AND ra_sub."date" = s."last_race_date"
        LIMIT 1
    )
JOIN "constructors" c_last ON r_last."constructor_id" = c_last."constructor_id"
JOIN "drivers" d ON s."driver_id" = d."driver_id"
WHERE c_first."constructor_id" = c_last."constructor_id"
ORDER BY d."full_name";
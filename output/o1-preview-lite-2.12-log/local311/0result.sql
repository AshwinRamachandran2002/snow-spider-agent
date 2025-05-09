SELECT c."name" AS "Constructor_Name", a."year" AS "Year", (a."constructor_points" + b."driver_points") AS "Combined_Points"
FROM (
   SELECT rs."constructor_id", r."year", SUM(rs."points") AS "constructor_points"
   FROM "results" rs
   JOIN "races" r ON rs."race_id" = r."race_id"
   GROUP BY rs."constructor_id", r."year"
) a
JOIN (
   SELECT r1."constructor_id", r1."year", r1."driver_points"
   FROM (
       SELECT rs."constructor_id", rs."driver_id", r."year", SUM(rs."points") AS "driver_points"
       FROM "results" rs
       JOIN "races" r ON rs."race_id" = r."race_id"
       GROUP BY rs."constructor_id", rs."driver_id", r."year"
   ) r1
   JOIN (
       SELECT constructor_id, year, MAX(driver_points) AS max_driver_points
       FROM (
           SELECT rs."constructor_id", rs."driver_id", r."year", SUM(rs."points") AS "driver_points"
           FROM "results" rs
           JOIN "races" r ON rs."race_id" = r."race_id"
           GROUP BY rs."constructor_id", rs."driver_id", r."year"
       ) r2
       GROUP BY constructor_id, year
   ) r3 ON r1."constructor_id" = r3."constructor_id" AND r1."year" = r3."year" AND r1."driver_points" = r3."max_driver_points"
) b ON a."constructor_id" = b."constructor_id" AND a."year" = b."year"
JOIN "constructors" c ON a."constructor_id" = c."constructor_id"
ORDER BY "Combined_Points" DESC
LIMIT 3;
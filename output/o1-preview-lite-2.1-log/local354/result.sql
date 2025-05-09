SELECT DISTINCT (d."forename" || ' ' || d."surname") AS "full_name", qualified_drivers."year"
FROM (
  SELECT start."driver_id", start."year"
  FROM (
    SELECT res."driver_id", ra."year", res."constructor_id" AS "start_constructor"
    FROM "results" AS res
    JOIN "races" AS ra ON res."race_id" = ra."race_id"
    JOIN (
      SELECT res2."driver_id", ra2."year", MIN(ra2."round") AS "first_round"
      FROM "results" AS res2
      JOIN "races" AS ra2 ON res2."race_id" = ra2."race_id"
      WHERE ra2."year" BETWEEN 1950 AND 1959
      GROUP BY res2."driver_id", ra2."year"
    ) AS first_race ON res."driver_id" = first_race."driver_id"
                     AND ra."year" = first_race."year"
                     AND ra."round" = first_race."first_round"
  ) AS start
  JOIN (
    SELECT res3."driver_id", ra3."year", res3."constructor_id" AS "end_constructor"
    FROM "results" AS res3
    JOIN "races" AS ra3 ON res3."race_id" = ra3."race_id"
    JOIN (
      SELECT res4."driver_id", ra4."year", MAX(ra4."round") AS "last_round"
      FROM "results" AS res4
      JOIN "races" AS ra4 ON res4."race_id" = ra4."race_id"
      WHERE ra4."year" BETWEEN 1950 AND 1959
      GROUP BY res4."driver_id", ra4."year"
    ) AS last_race ON res3."driver_id" = last_race."driver_id"
                     AND ra3."year" = last_race."year"
                     AND ra3."round" = last_race."last_round"
  ) AS end ON start."driver_id" = end."driver_id"
            AND start."year" = end."year"
  WHERE start."start_constructor" = end."end_constructor"
) AS qualified_drivers
JOIN (
  SELECT res5."driver_id", ra5."year", COUNT(DISTINCT ra5."race_id") AS "race_count"
  FROM "results" AS res5
  JOIN "races" AS ra5 ON res5."race_id" = ra5."race_id"
  WHERE ra5."year" BETWEEN 1950 AND 1959
  GROUP BY res5."driver_id", ra5."year"
  HAVING "race_count" >= 2
) AS race_counts ON qualified_drivers."driver_id" = race_counts."driver_id"
                 AND qualified_drivers."year" = race_counts."year"
JOIN "drivers" AS d ON d."driver_id" = qualified_drivers."driver_id"
ORDER BY d."surname", d."forename", qualified_drivers."year";
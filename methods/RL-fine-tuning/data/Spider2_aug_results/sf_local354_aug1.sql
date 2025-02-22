-- Task: For each driver in each season between 1950 and 1959, find the first and last rounds they participated in.
SELECT
  races."year",
  results."driver_id",
  MIN(races."round") AS "first_round",
  MAX(races."round") AS "last_round"
FROM 
    F1.F1.RESULTS results
INNER JOIN F1.F1.RACES races ON races."race_id" = results."race_id"
WHERE
    races."year" BETWEEN 1950 AND 1959
GROUP BY 
    races."year", 
    results."driver_id";
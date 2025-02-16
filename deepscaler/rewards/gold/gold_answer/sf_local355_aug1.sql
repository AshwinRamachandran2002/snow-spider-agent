-- Task: List up to 100 drivers who missed fewer than three races in any year, along with the number of missed races each year.
WITH hiatus_prelim AS (
  SELECT DISTINCT
    races."year",
    driver_standings."driver_id",
    races."round"
  FROM F1.F1.DRIVER_STANDINGS_EXT AS driver_standings
  INNER JOIN F1.F1.RACES_EXT AS races ON races."race_id" = driver_standings."race_id"
  LEFT JOIN F1.F1.RESULTS AS results
    ON results."race_id" = driver_standings."race_id"
    AND results."driver_id" = driver_standings."driver_id"
  WHERE results."driver_id" IS NULL
)
SELECT
  "driver_id",
  "year",
  COUNT(*) AS "missed_count"
FROM hiatus_prelim
GROUP BY "driver_id", "year"
HAVING COUNT(*) < 3
LIMIT 100;
-- Task: For each year, list each driver along with their total points.
SELECT races.year,
       drivers.forename || ' ' || drivers.surname AS driver,
       SUM(results.points) AS points
FROM results
LEFT JOIN races ON results.race_id = races.race_id
LEFT JOIN drivers ON results.driver_id = drivers.driver_id
GROUP BY races.year, driver
ORDER BY races.year, points DESC;
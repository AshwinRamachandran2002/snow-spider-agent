WITH Participations AS (
    SELECT r.driver_id, ra.year, ra.round, r.constructor_id
    FROM results r
    JOIN races ra ON r.race_id = ra.race_id
    WHERE ra.year BETWEEN 1950 AND 1959
),
Driver_Seasons AS (
    SELECT driver_id, year
    FROM Participations
    GROUP BY driver_id, year
    HAVING COUNT(DISTINCT round) >= 2
),
First_Race AS (
    SELECT p.driver_id, p.year, p.constructor_id AS first_constructor_id
    FROM Participations p
    WHERE (p.driver_id, p.year) IN (SELECT driver_id, year FROM Driver_Seasons)
      AND p.round = (SELECT MIN(p2.round) FROM Participations p2 WHERE p2.driver_id = p.driver_id AND p2.year = p.year)
),
Last_Race AS (
    SELECT p.driver_id, p.year, p.constructor_id AS last_constructor_id
    FROM Participations p
    WHERE (p.driver_id, p.year) IN (SELECT driver_id, year FROM Driver_Seasons)
      AND p.round = (SELECT MAX(p2.round) FROM Participations p2 WHERE p2.driver_id = p.driver_id AND p2.year = p.year)
),
Drivers_Same_Constructor AS (
    SELECT fr.driver_id, fr.year, fr.first_constructor_id
    FROM First_Race fr
    JOIN Last_Race lr ON fr.driver_id = lr.driver_id AND fr.year = lr.year
    WHERE fr.first_constructor_id = lr.last_constructor_id
),
Final_Result AS (
    SELECT d.driver_id, d.full_name AS driver_name, dsc.year, c.constructor_id, c.name AS constructor_name
    FROM Drivers_Same_Constructor dsc
    JOIN drivers d ON d.driver_id = dsc.driver_id
    JOIN constructors c ON c.constructor_id = dsc.first_constructor_id
)
SELECT driver_id, driver_name, year, constructor_id, constructor_name
FROM Final_Result
ORDER BY driver_name, year;
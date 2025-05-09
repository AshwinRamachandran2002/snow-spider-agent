WITH start_overtakes AS (
  SELECT SUM(
    CASE WHEN r.grid > lt.position THEN r.grid - lt.position ELSE 0 END
  ) AS num_overtakes
  FROM results r
  JOIN lap_times lt ON r.race_id = lt.race_id AND r.driver_id = lt.driver_id
  WHERE r.race_id = 1 AND lt.lap = 1
),
standard_overtakes AS (
  SELECT SUM(
    CASE WHEN (dp_prev.position - dp_current.position) > 0 THEN (dp_prev.position - dp_current.position) ELSE 0 END
  ) AS num_overtakes
  FROM (
    SELECT lt.driver_id, lt.lap, lt.position
    FROM lap_times lt
    WHERE lt.race_id = 1 AND lt.lap BETWEEN 1 AND 4
  ) dp_prev
  JOIN (
    SELECT lt.driver_id, lt.lap, lt.position
    FROM lap_times lt
    WHERE lt.race_id = 1 AND lt.lap BETWEEN 2 AND 5
  ) dp_current ON dp_current.driver_id = dp_prev.driver_id AND dp_current.lap = dp_prev.lap + 1
  LEFT JOIN (
    SELECT DISTINCT driver_id, lap
    FROM pit_stops
    WHERE pit_stops.race_id = 1 AND pit_stops.lap BETWEEN 1 AND 5
  ) ps ON dp_current.lap = ps.lap AND dp_current.driver_id = ps.driver_id
  LEFT JOIN (
    SELECT DISTINCT driver_id, lap
    FROM retirements
    WHERE retirements.race_id = 1 AND retirements.lap BETWEEN 1 AND 5
  ) rt ON dp_current.lap = rt.lap AND dp_current.driver_id = rt.driver_id
  WHERE ps.driver_id IS NULL AND rt.driver_id IS NULL
),
pit_stop_overtakes AS (
  SELECT COUNT(*) AS num_overtakes
  FROM pit_stops
  WHERE pit_stops.race_id = 1 AND pit_stops.lap BETWEEN 1 AND 5
),
retirement_overtakes AS (
  SELECT COUNT(*) AS num_overtakes
  FROM retirements
  WHERE retirements.race_id = 1 AND retirements.lap BETWEEN 1 AND 5
)
SELECT 'Retirements' AS Category, num_overtakes AS "Number of Overtakes" FROM retirement_overtakes
UNION ALL
SELECT 'Pit Stops', num_overtakes FROM pit_stop_overtakes
UNION ALL
SELECT 'Start-Related Overtakes', num_overtakes FROM start_overtakes
UNION ALL
SELECT 'Standard On-Track Passes', num_overtakes FROM standard_overtakes;
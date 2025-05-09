WITH overtakes AS (
    SELECT p1.driver_id,
           COUNT(*) AS gained
    FROM lap_positions AS p1
    JOIN lap_positions AS p2
         ON p2.race_id   = p1.race_id
        AND p2.driver_id = p1.driver_id
        AND p2.lap       = p1.lap + 1
    LEFT JOIN pit_stops AS ps
           ON ps.race_id   = p2.race_id
          AND ps.driver_id = p2.driver_id
          AND ps.lap       = p2.lap
    LEFT JOIN retirements AS rt
           ON rt.race_id   = p2.race_id
          AND rt.driver_id = p2.driver_id
          AND rt.lap       = p2.lap
    WHERE p1.lap_type   = 'Race'
      AND p2.lap_type   = 'Race'
      AND p1.lap        > 0         -- ignore first-lap (start) changes
      AND p2.position   < p1.position  -- positions gained
      AND ps.lap IS NULL            -- exclude pit-stop laps
      AND rt.lap IS NULL            -- exclude retirement laps
    GROUP BY p1.driver_id
),
overtaken AS (
    SELECT p1.driver_id,
           COUNT(*) AS lost
    FROM lap_positions AS p1
    JOIN lap_positions AS p2
         ON p2.race_id   = p1.race_id
        AND p2.driver_id = p1.driver_id
        AND p2.lap       = p1.lap + 1
    LEFT JOIN pit_stops AS ps
           ON ps.race_id   = p2.race_id
          AND ps.driver_id = p2.driver_id
          AND ps.lap       = p2.lap
    LEFT JOIN retirements AS rt
           ON rt.race_id   = p2.race_id
          AND rt.driver_id = p2.driver_id
          AND rt.lap       = p2.lap
    WHERE p1.lap_type   = 'Race'
      AND p2.lap_type   = 'Race'
      AND p1.lap        > 0         -- ignore first-lap (start) changes
      AND p2.position   > p1.position  -- positions lost
      AND ps.lap IS NULL
      AND rt.lap IS NULL
    GROUP BY p1.driver_id
)
SELECT DISTINCT d.forename || ' ' || d.surname AS full_name
FROM drivers AS d
LEFT JOIN overtakes AS g ON g.driver_id = d.driver_id
LEFT JOIN overtaken AS l ON l.driver_id = d.driver_id
WHERE COALESCE(l.lost, 0) > COALESCE(g.gained, 0)
ORDER BY full_name;
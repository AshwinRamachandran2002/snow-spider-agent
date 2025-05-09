WITH
grid_positions AS (
    SELECT r.driver_id, r.grid
    FROM results r
    WHERE r.race_id = 1
),
lap1_positions AS (
    SELECT lp.driver_id, lp.position AS lap1_position
    FROM lap_positions lp
    WHERE lp.race_id = 1 AND lp.lap = 1
),
start_overtakes AS (
    SELECT
        gp.driver_id,
        gp.grid,
        lp1.lap1_position,
        (gp.grid - lp1.lap1_position) AS position_change
    FROM grid_positions gp
    JOIN lap1_positions lp1 ON gp.driver_id = lp1.driver_id
    WHERE gp.grid != lp1.lap1_position
),
total_start_overtakes AS (
    SELECT
        SUM(ABS(position_change)) / 2 AS num_overtakes
    FROM start_overtakes
),
lap_changes AS (
    SELECT
        lp1.driver_id,
        lp1.lap AS lap_n,
        lp1.position AS position_n,
        lp2.lap AS lap_n_plus_1,
        lp2.position AS position_n_plus_1,
        (lp2.position - lp1.position) AS position_change
    FROM lap_positions lp1
    JOIN lap_positions lp2 ON
        lp1.driver_id = lp2.driver_id AND
        lp1.race_id = lp2.race_id AND
        lp2.lap = lp1.lap + 1
    LEFT JOIN pit_stops ps ON
        lp1.driver_id = ps.driver_id AND
        lp1.race_id = ps.race_id AND
        ps.lap = lp1.lap
    LEFT JOIN retirements r ON
        lp1.driver_id = r.driver_id AND
        lp1.race_id = r.race_id AND
        r.lap = lp1.lap
    WHERE lp1.race_id = 1 AND lp1.lap BETWEEN 1 AND 4
      AND ps.driver_id IS NULL
      AND r.driver_id IS NULL
),
standard_overtakes AS (
    SELECT
        SUM(CASE WHEN position_change != 0 THEN 1 ELSE 0 END) / 2 AS num_overtakes
        FROM lap_changes
),
retirements_in_first_5_laps AS (
    SELECT COUNT(*) AS num_retirements
    FROM retirements r
    WHERE r.race_id = 1 AND r.lap <= 5
),
pit_stops_in_first_5_laps AS (
    SELECT COUNT(*) AS num_pit_stops
    FROM pit_stops p
    WHERE p.race_id = 1 AND p.lap <= 5
),
final_counts AS (
    SELECT 'Retirements' AS Category, num_retirements AS "Number of Overtakes" FROM retirements_in_first_5_laps
    UNION ALL
    SELECT 'Pit Stops', num_pit_stops FROM pit_stops_in_first_5_laps
    UNION ALL
    SELECT 'Start-Related Overtakes', CAST(num_overtakes AS INT) FROM total_start_overtakes
    UNION ALL
    SELECT 'Standard On-Track Passes', CAST(num_overtakes AS INT) FROM standard_overtakes
)
SELECT Category, "Number of Overtakes"
FROM final_counts;
WITH races_with_pit_stops AS (
    SELECT DISTINCT race_id FROM pit_stops
),
driver_positions AS (
    SELECT race_id, lap, driver_id, position
    FROM lap_times
    WHERE race_id IN (SELECT race_id FROM races_with_pit_stops)
),
driver_positions_prev AS (
    SELECT race_id, lap + 1 AS lap, driver_id, position AS position_prev
    FROM driver_positions
),
driver_grid_positions AS (
    SELECT race_id, driver_id, grid AS position_prev
    FROM results
    WHERE race_id IN (SELECT race_id FROM races_with_pit_stops)
),
driver_positions_combined AS (
    SELECT dp.race_id, dp.lap, dp.driver_id, dp.position,
           CASE
               WHEN dp.lap = 1 THEN dgp.position_prev
               ELSE dpp.position_prev
           END AS position_prev
    FROM driver_positions dp
    LEFT JOIN driver_positions_prev dpp 
        ON dp.race_id = dpp.race_id 
        AND dp.lap = dpp.lap 
        AND dp.driver_id = dpp.driver_id
    LEFT JOIN driver_grid_positions dgp 
        ON dp.race_id = dgp.race_id 
        AND dp.driver_id = dgp.driver_id
),
driver_pit_stops AS (
    SELECT race_id, driver_id, lap
    FROM pit_stops
),
driver_retirements AS (
    SELECT race_id, driver_id, lap AS retirement_lap
    FROM retirements
),
driver_pairs_with_info AS (
    SELECT 
        dpc1.race_id, dpc1.lap,
        dpc1.driver_id AS driver_a, dpc1.position AS position_a, dpc1.position_prev AS position_a_prev,
        dpc2.driver_id AS driver_b, dpc2.position AS position_b, dpc2.position_prev AS position_b_prev,
        CASE WHEN dpa.lap IS NOT NULL THEN 1 ELSE 0 END AS driver_a_pitted,
        CASE WHEN dra.retirement_lap IS NOT NULL THEN 1 ELSE 0 END AS driver_a_retired
    FROM driver_positions_combined dpc1
    JOIN driver_positions_combined dpc2
        ON dpc1.race_id = dpc2.race_id
        AND dpc1.lap = dpc2.lap
        AND dpc1.driver_id <> dpc2.driver_id
    LEFT JOIN driver_pit_stops dpa
        ON dpc1.race_id = dpa.race_id 
        AND dpc1.driver_id = dpa.driver_id 
        AND dpc1.lap = dpa.lap
    LEFT JOIN driver_retirements dra
        ON dpc1.race_id = dra.race_id 
        AND dra.driver_id = dpc1.driver_id 
        AND dra.retirement_lap = dpc1.lap
    WHERE 
        dpc1.position_prev IS NOT NULL 
        AND dpc2.position_prev IS NOT NULL
),
overtakes AS (
    SELECT *,
    CASE
        WHEN dpc.lap = 1 THEN 'Race_Start_Overtake'
        WHEN driver_a_retired = 1 THEN 'Overtake_Due_To_Retirement'
        WHEN driver_a_pitted = 1 THEN 'Pit_Stop_Overtake'
        ELSE 'On_Track_Overtake'
    END AS Overtake_Type
    FROM driver_pairs_with_info dpc
    WHERE dpc.position_a_prev < dpc.position_b_prev
      AND dpc.position_a > dpc.position_b
)
SELECT Overtake_Type, COUNT(DISTINCT race_id || '-' || lap || '-' || driver_a || '-' || driver_b) AS Count 
FROM overtakes 
GROUP BY Overtake_Type;
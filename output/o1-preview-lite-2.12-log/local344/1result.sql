WITH
on_track_overtakes AS (
    SELECT COUNT(*) AS num_overtakes
    FROM (
        SELECT lt1.race_id, lt1.driver_id, lt1.lap
        FROM "lap_times" lt1
        JOIN "lap_times" lt2
            ON lt1.race_id = lt2.race_id
            AND lt1.driver_id = lt2.driver_id
            AND lt1.lap = lt2.lap - 1
        LEFT JOIN "pit_stops" ps
            ON lt1.race_id = ps.race_id
            AND ps.lap = lt2.lap
            AND ps.driver_id IN (
                SELECT driver_id
                FROM "lap_times"
                WHERE race_id = lt1.race_id AND lap = lt1.lap
                AND position < lt1.position
            )
        LEFT JOIN "retirements" rt
            ON lt1.race_id = rt.race_id
            AND rt.lap = lt2.lap
            AND rt.driver_id IN (
                SELECT driver_id
                FROM "lap_times"
                WHERE race_id = lt1.race_id AND lap = lt1.lap
                AND position < lt1.position
            )
        WHERE lt1.position > lt2.position
            AND ps.driver_id IS NULL
            AND rt.driver_id IS NULL
    )
),
pit_stop_overtakes AS (
    SELECT COUNT(*) AS num_overtakes
    FROM (
        SELECT lt1.race_id, lt1.driver_id, lt1.lap
        FROM "lap_times" lt1
        JOIN "lap_times" lt2
            ON lt1.race_id = lt2.race_id
            AND lt1.driver_id = lt2.driver_id
            AND lt1.lap = lt2.lap - 1
        JOIN "pit_stops" ps
            ON lt1.race_id = ps.race_id
            AND ps.lap = lt2.lap
            AND ps.driver_id IN (
                SELECT driver_id
                FROM "lap_times"
                WHERE race_id = lt1.race_id AND lap = lt1.lap
                AND position < lt1.position
            )
        WHERE lt1.position > lt2.position
    )
),
retirement_overtakes AS (
    SELECT COUNT(*) AS num_overtakes
    FROM (
        SELECT lt1.race_id, lt1.driver_id, lt1.lap
        FROM "lap_times" lt1
        JOIN "lap_times" lt2
            ON lt1.race_id = lt2.race_id
            AND lt1.driver_id = lt2.driver_id
            AND lt1.lap = lt2.lap - 1
        JOIN "retirements" rt
            ON lt1.race_id = rt.race_id
            AND rt.lap = lt2.lap
            AND rt.driver_id IN (
                SELECT driver_id
                FROM "lap_times"
                WHERE race_id = lt1.race_id AND lap = lt1.lap
                AND position < lt1.position
            )
        WHERE lt1.position > lt2.position
    )
),
penalty_overtakes AS (
    SELECT 0 AS num_overtakes
)
SELECT 'On-track overtakes' AS "Overtake_Type", (SELECT num_overtakes FROM on_track_overtakes) AS "Number_of_Times"
UNION ALL
SELECT 'Pit stop overtakes', (SELECT num_overtakes FROM pit_stop_overtakes)
UNION ALL
SELECT 'Overtakes due to retirements', (SELECT num_overtakes FROM retirement_overtakes)
UNION ALL
SELECT 'Overtakes due to penalties', (SELECT num_overtakes FROM penalty_overtakes);
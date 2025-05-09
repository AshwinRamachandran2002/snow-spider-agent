WITH
-- Compute total overtakes: instances where a driver improves position between laps
overtakes AS (
    SELECT
        lp1."race_id",
        lp1."lap",
        lp1."driver_id",
        lp0."position" AS prev_position,
        lp1."position" AS curr_position
    FROM
        "lap_positions" lp1
    JOIN "lap_positions" lp0 ON
        lp1."race_id" = lp0."race_id" AND
        lp1."driver_id" = lp0."driver_id" AND
        lp1."lap" = lp0."lap" + 1
    WHERE
        lp1."position" < lp0."position"
),
-- Overtakes due to pit stops: when a driver gains position because another driver pitted
overtakes_pit_stops AS (
    SELECT
        o.*
    FROM
        overtakes o
    JOIN "pit_stops" ps ON
        o."race_id" = ps."race_id" AND
        ps."lap" = o."lap"
    WHERE
        EXISTS (
            SELECT 1
            FROM "lap_positions" lp_prev
            WHERE
                lp_prev."race_id" = o."race_id" AND
                lp_prev."lap" = o."lap" - 1 AND
                lp_prev."position" < o.prev_position AND
                lp_prev."position" > o.curr_position AND
                lp_prev."driver_id" = ps."driver_id"
        )
),
-- Overtakes due to retirements: when a driver gains position because another driver retired
overtakes_retirements AS (
    SELECT
        o.*
    FROM
        overtakes o
    JOIN "retirements" r ON
        o."race_id" = r."race_id" AND
        r."lap" = o."lap"
    WHERE
        EXISTS (
            SELECT 1
            FROM "lap_positions" lp_prev
            WHERE
                lp_prev."race_id" = o."race_id" AND
                lp_prev."lap" = o."lap" - 1 AND
                lp_prev."position" < o.prev_position AND
                lp_prev."position" > o.curr_position AND
                lp_prev."driver_id" = r."driver_id"
            )
),
-- On-track overtakes: total overtakes excluding pit stop and retirement overtakes
on_track_overtakes AS (
    SELECT
        o.*
    FROM
        overtakes o
    LEFT JOIN overtakes_pit_stops ops ON
        o."race_id" = ops."race_id" AND
        o."lap" = ops."lap" AND
        o."driver_id" = ops."driver_id"
    LEFT JOIN overtakes_retirements orr ON
        o."race_id" = orr."race_id" AND
        o."lap" = orr."lap" AND
        o."driver_id" = orr."driver_id"
    WHERE
        ops."race_id" IS NULL AND
        orr."race_id" IS NULL
)
SELECT 'On-track overtakes' AS Overtake_Type, COUNT(*) AS Number_of_Times
FROM on_track_overtakes
UNION ALL
SELECT 'Pit stop overtakes', COUNT(*) FROM overtakes_pit_stops
UNION ALL
SELECT 'Overtakes due to retirements', COUNT(*) FROM overtakes_retirements
UNION ALL
SELECT 'Overtakes due to penalties', 0
;
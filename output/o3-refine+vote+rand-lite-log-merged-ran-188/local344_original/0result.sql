WITH races_with_pit AS (                -- only races that actually have pit‑stop information
    SELECT DISTINCT race_id
    FROM pit_stops
),

driver_positions AS (                   -- every recorded race‑lap position for those races
    SELECT
        lp."race_id",
        lp."driver_id",
        lp."lap",
        lp."position",
        LAG(lp."position")
            OVER (PARTITION BY lp."race_id", lp."driver_id" ORDER BY lp."lap") AS prev_position
    FROM lap_positions lp
    WHERE lp."race_id" IN (SELECT race_id FROM races_with_pit)
),

position_changes AS (                   -- keep laps where the driver’s position changed
    SELECT
        dp.*,
        (dp.prev_position - dp."position") AS delta          -- +ve = gained, –ve = lost places
    FROM driver_positions dp
    WHERE dp.prev_position IS NOT NULL
      AND dp.prev_position <> dp."position"
),

lost_positions AS (                     -- we only need situations where the driver LOST positions
    SELECT
        pc.*,
        -pc.delta AS positions_lost                           -- number of cars that passed him
    FROM position_changes pc
    WHERE pc.delta < 0
),

classified AS (                         -- label each loss with a “type” of overtake
    SELECT
        lp."race_id",
        lp."driver_id",
        lp."lap",
        lp.positions_lost,
        CASE
            /* car stopped and others went by */
            WHEN EXISTS (SELECT 1
                         FROM retirements r
                         WHERE r."race_id" = lp."race_id"
                           AND r."driver_id" = lp."driver_id"
                           AND r."lap"       = lp."lap")               THEN 'Retirement'

            /* driver himself dove into the pits */
            WHEN EXISTS (SELECT 1
                         FROM pit_stops ps
                         WHERE ps."race_id" = lp."race_id"
                           AND ps."driver_id" = lp."driver_id"
                           AND ps."lap"       = lp."lap")              THEN 'Pit Entry'

            /* grid shuffle at the start */
            WHEN lp."lap" = 1                                           THEN 'Race Start'

            /* somebody else exited the pits ahead of him */
            WHEN EXISTS (SELECT 1
                         FROM pit_stops ps
                         WHERE ps."race_id" = lp."race_id"
                           AND ps."lap"       = lp."lap"
                           AND ps."driver_id" <> lp."driver_id")        THEN 'Pit Exit'

            /* normal on‑track pass */
            ELSE 'On‑track'
        END AS overtake_type
    FROM lost_positions lp
)

SELECT
    overtake_type,
    SUM(positions_lost) AS number_of_overtakes
FROM classified
GROUP BY overtake_type
ORDER BY number_of_overtakes DESC;
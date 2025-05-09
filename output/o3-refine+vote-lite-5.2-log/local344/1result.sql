WITH pit_races AS (                 -- only look at races that have pit‑stop data
    SELECT race_id
    FROM races_ext
    WHERE is_pit_data_available = 1
),

driver_laps AS (                    -- position of every driver on every race lap
    SELECT
        lp.race_id,
        lp.driver_id,
        lp.lap,
        lp.position,
        LAG(lp.position) OVER (                 -- position on the previous lap
            PARTITION BY lp.race_id, lp.driver_id
            ORDER BY lp.lap
        ) AS prev_position
    FROM lap_positions lp
    JOIN pit_races pr ON pr.race_id = lp.race_id
    WHERE lp.lap_type = 'Race'                    -- ignore formation / grid rows
),

overtake_candidates AS (            -- laps in which the driver moved forward
    SELECT
        race_id,
        driver_id,
        lap
    FROM driver_laps
    WHERE prev_position IS NOT NULL
      AND position < prev_position               -- gained at least one place
),

classified AS (                     -- decide *how* the gain happened
    SELECT
        oc.race_id,
        oc.driver_id,
        oc.lap,
        CASE
            WHEN oc.lap = 1 THEN 'Race Start'    -- grid -> first‑lap changes
            WHEN EXISTS (                        -- another car retired this lap
                   SELECT 1
                   FROM retirements r
                   WHERE r.race_id = oc.race_id
                     AND r.lap      = oc.lap
            ) THEN 'Retirement'
            WHEN EXISTS (                        -- someone pitted this lap
                   SELECT 1
                   FROM pit_stops ps
                   WHERE ps.race_id = oc.race_id
                     AND ps.lap     = oc.lap
            ) THEN 'Pit Stop'
            ELSE 'On Track'                      -- genuine on‑track overtake
        END AS overtake_type
    FROM overtake_candidates oc
)

SELECT
    overtake_type,
    COUNT(*) AS overtake_count
FROM classified
GROUP BY overtake_type
ORDER BY overtake_count DESC;
WITH positions AS (
    SELECT
        race_id,
        driver_id,
        lap,
        position,
        lap_type,
        LAG(position) OVER (
            PARTITION BY race_id, driver_id
            ORDER BY lap
        ) AS prev_position
    FROM lap_positions
    WHERE lap BETWEEN 0 AND 5          -- include lap‑0 grid plus first five race laps
),
overtakes AS (
    /* an over‑take is recorded whenever the driver’s position number decreases
       (e.g. from 10th to 7th => gained 3 positions)                           */
    SELECT
        CASE
            WHEN lap = 1                                            THEN 'start_related'
            WHEN lap_type LIKE '%Retirement%'                       THEN 'retirements'
            WHEN lap_type LIKE '%Pit Stop%'                         THEN 'pit_stops'
            ELSE                                                         'standard_on_track'
        END                                   AS category,
        (prev_position - position)            AS gained_positions
    FROM positions
    WHERE prev_position IS NOT NULL
      AND position < prev_position            -- driver moved forward
)
SELECT
    category,
    SUM(gained_positions) AS overtakes
FROM overtakes
GROUP BY category
ORDER BY category;
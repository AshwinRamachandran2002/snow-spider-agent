WITH pos AS (
    SELECT
        lp."race_id",
        lp."driver_id",
        lp."lap",
        lp."position",
        LAG(lp."position") OVER (
            PARTITION BY lp."race_id", lp."driver_id"
            ORDER BY lp."lap"
        ) AS "prev_pos"
    FROM "lap_positions" lp
    WHERE lp."lap_type" = 'Race'      -- only racing laps
      AND lp."lap" > 1                -- exclude first-lap (start) changes
),
no_pit AS (                           -- drop laps where the driver pitted
    SELECT p.*
    FROM pos p
    LEFT JOIN "pit_stops" ps
           ON ps."race_id"   = p."race_id"
          AND ps."driver_id" = p."driver_id"
          AND ps."lap"       = p."lap"
    WHERE ps."lap" IS NULL
),
no_ret AS (                           -- drop laps on/after a retirement lap
    SELECT np.*
    FROM no_pit np
    LEFT JOIN "retirements" r
           ON r."race_id"   = np."race_id"
          AND r."driver_id" = np."driver_id"
          AND np."lap"     >= r."lap"
    WHERE r."lap" IS NULL
),
changes AS (                          -- aggregate on-track position changes
    SELECT
        "driver_id",
        SUM(CASE WHEN "prev_pos" > "position" THEN "prev_pos" - "position" ELSE 0 END) AS overtakes_made,
        SUM(CASE WHEN "prev_pos" < "position" THEN "position" - "prev_pos" ELSE 0 END) AS overtakes_lost
    FROM no_ret
    GROUP BY "driver_id"
)
SELECT d."full_name"
FROM changes c
JOIN "drivers_ext" d ON d."driver_id" = c."driver_id"
WHERE c."overtakes_lost" > c."overtakes_made"   -- lost more places than gained
ORDER BY d."full_name";
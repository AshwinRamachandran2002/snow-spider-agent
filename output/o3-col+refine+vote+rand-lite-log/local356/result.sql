WITH retirement_laps AS (
    SELECT 
        "race_id",
        "driver_id",
        MIN("lap") AS "retire_lap"
    FROM "retirements"
    GROUP BY "race_id", "driver_id"
),
race_laps AS (
    SELECT
        lp."race_id",
        lp."driver_id",
        lp."lap",
        lp."position",
        LAG(lp."position") OVER (
            PARTITION BY lp."race_id", lp."driver_id"
            ORDER BY lp."lap"
        ) AS "prev_position"
    FROM "lap_positions" AS lp
    WHERE lp."lap_type" = 'Race'
),
clean_laps AS (
    SELECT rl.*
    FROM race_laps rl
    LEFT JOIN "pit_stops" ps
           ON rl."race_id"   = ps."race_id"
          AND rl."driver_id" = ps."driver_id"
          AND rl."lap"       = ps."lap"
    LEFT JOIN retirement_laps r
           ON rl."race_id"   = r."race_id"
          AND rl."driver_id" = r."driver_id"
    WHERE rl."prev_position" IS NOT NULL          -- ignore first recorded lap
      AND rl."lap" > 1                             -- exclude start-lap movements
      AND ps."lap" IS NULL                         -- exclude laps with pit stops
      AND (r."retire_lap" IS NULL                 -- exclude laps after retirement
           OR rl."lap" < r."retire_lap")
),
deltas AS (
    SELECT
        "driver_id",
        ("prev_position" - "position") AS "delta"
    FROM clean_laps
),
agg AS (
    SELECT
        "driver_id",
        SUM(CASE WHEN delta > 0 THEN  delta ELSE 0 END)                  AS "overtakes_made",
        ABS(SUM(CASE WHEN delta < 0 THEN delta ELSE 0 END))              AS "times_overtaken"
    FROM deltas
    GROUP BY "driver_id"
)
SELECT DISTINCT
       d."full_name"
FROM   agg
JOIN   "drivers_ext" d
       ON d."driver_id" = agg."driver_id"
WHERE  "times_overtaken" > "overtakes_made"
ORDER  BY d."full_name";
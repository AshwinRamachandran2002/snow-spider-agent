WITH pit_laps AS (        -- laps in which a pit-stop occurred
    SELECT DISTINCT
           "race_id",
           "driver_id",
           "lap"
    FROM F1.F1.PIT_STOPS
),

retirement_laps AS (      -- laps in which any retirement occurred
    SELECT DISTINCT
           "race_id",
           "lap"
    FROM F1.F1.RETIREMENTS
),

lap_changes AS (          -- position on every lap plus previous-lap position
    SELECT
        lp."race_id",
        lp."driver_id",
        lp."lap",
        lp."position",
        LAG(lp."position") OVER (
            PARTITION BY lp."race_id", lp."driver_id"
            ORDER BY     lp."lap"
        ) AS "prev_position"
    FROM F1.F1.LAP_POSITIONS lp
    WHERE lp."lap_type" = 'Race'
),

valid_changes AS (        -- on-track position changes we want to count
    SELECT
        lc."driver_id",
        CASE
            WHEN lc."prev_position" > lc."position"
            THEN lc."prev_position" - lc."position"
            ELSE 0
        END AS "overtakes",
        CASE
            WHEN lc."position" > lc."prev_position"
            THEN lc."position" - lc."prev_position"
            ELSE 0
        END AS "overtaken_by"
    FROM lap_changes lc
    WHERE lc."lap" > 1                     -- exclude first-lap start movements
      AND lc."prev_position" IS NOT NULL
      AND NOT EXISTS (                     -- exclude driver’s own pit-stop lap
            SELECT 1
            FROM   pit_laps pl
            WHERE  pl."race_id"   = lc."race_id"
              AND  pl."driver_id" = lc."driver_id"
              AND  pl."lap"       = lc."lap"
      )
      AND NOT EXISTS (                     -- exclude laps with any retirement
            SELECT 1
            FROM   retirement_laps rl
            WHERE  rl."race_id" = lc."race_id"
              AND  rl."lap"     = lc."lap"
      )
),

driver_totals AS (        -- aggregate per driver
    SELECT
        "driver_id",
        SUM("overtakes")     AS "total_overtakes",
        SUM("overtaken_by")  AS "total_overtaken_by"
    FROM valid_changes
    GROUP BY "driver_id"
    HAVING SUM("overtaken_by") > SUM("overtakes")   -- net negative
)

SELECT
    d."full_name"
FROM driver_totals dt
JOIN F1.F1.DRIVERS d
  ON d."driver_id" = dt."driver_id"
ORDER BY d."full_name";
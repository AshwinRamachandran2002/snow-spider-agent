WITH race_with_pit AS (          -- 1. races that have pit-stop data
    SELECT "race_id"
    FROM   F1.F1.RACES_EXT
    WHERE  "is_pit_data_available" = 1
),
lap_pos AS (                     -- 2. every lap position for those races
    SELECT lp."race_id",
           lp."lap",
           lp."driver_id",
           lp."position"
    FROM   F1.F1.LAP_POSITIONS lp
           JOIN race_with_pit r  ON r."race_id" = lp."race_id"
    WHERE  lp."lap_type" = 'Race'
),
lap_pos_w_prev AS (              -- 3. current & previous-lap position per driver
    SELECT lp.*,
           LAG(lp."position") OVER(PARTITION BY lp."race_id", lp."driver_id"
                                    ORDER BY lp."lap")     AS "prev_position"
    FROM   lap_pos lp
),
valid_laps AS (                  -- 4. keep laps where we have a previous record
    SELECT *
    FROM   lap_pos_w_prev
    WHERE  "prev_position" IS NOT NULL
),
overtake_pairs AS (              -- 5. driver A now ahead of B but was behind
    SELECT a."race_id",
           a."lap",
           a."driver_id"  AS "overtaker_id",
           b."driver_id"  AS "overtaken_id"
    FROM   valid_laps a
           JOIN valid_laps b
             ON  a."race_id" = b."race_id"
             AND a."lap"     = b."lap"
             AND a."driver_id" <> b."driver_id"
    WHERE  a."position"      <  b."position"      -- A now ahead
      AND  a."prev_position" >  b."prev_position" -- A was behind
),
classify AS (                    -- 6. join info required for labels
    SELECT p.*,
           r."driver_id"          AS "retired_here",
           ps."driver_id"         AS "pitted_here",
           psp."driver_id"        AS "pitted_prev",
           ra."grid"              AS "grid_a",
           rb."grid"              AS "grid_b"
    FROM   overtake_pairs p
           LEFT JOIN F1.F1.RETIREMENTS     r
                  ON  r."race_id" = p."race_id"
                  AND r."driver_id" = p."overtaken_id"
                  AND r."lap" = p."lap"
           LEFT JOIN F1.F1.PIT_STOPS      ps
                  ON  ps."race_id" = p."race_id"
                  AND ps."driver_id" = p."overtaken_id"
                  AND ps."lap" = p."lap"
           LEFT JOIN F1.F1.PIT_STOPS      psp
                  ON  psp."race_id" = p."race_id"
                  AND psp."driver_id" = p."overtaken_id"
                  AND psp."lap" = p."lap" - 1
           LEFT JOIN F1.F1.RESULTS        ra
                  ON  ra."race_id" = p."race_id"
                  AND ra."driver_id" = p."overtaker_id"
           LEFT JOIN F1.F1.RESULTS        rb
                  ON  rb."race_id" = p."race_id"
                  AND rb."driver_id" = p."overtaken_id"
),
overtake_types AS (              -- 7. apply precedence R > P > S > T
    SELECT
        CASE
            WHEN "retired_here" IS NOT NULL
                 THEN 'R'                                   -- Retirement
            WHEN "pitted_here" IS NOT NULL
              OR "pitted_prev" IS NOT NULL
                 THEN 'P'                                   -- Pit entry / exit
            WHEN "lap" = 1
             AND ABS("grid_a" - "grid_b") <= 2
                 THEN 'S'                                   -- Race start
            ELSE 'T'                                        -- Normal track
        END AS "overtake_type"
    FROM   classify
)
SELECT "overtake_type",
       COUNT(*) AS "num_overtakes"
FROM   overtake_types
GROUP  BY "overtake_type"
ORDER  BY "num_overtakes" DESC NULLS LAST;
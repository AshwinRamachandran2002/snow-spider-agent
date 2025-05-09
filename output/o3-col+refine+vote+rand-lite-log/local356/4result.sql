WITH race_positions AS (
    -- race-lap positions excluding the first racing lap
    SELECT lp."race_id",
           lp."driver_id",
           lp."lap",
           lp."position"
    FROM   "lap_positions" lp
    WHERE  lp."lap_type" = 'Race'   -- ignore grid, retirements, etc.
      AND  lp."lap"      > 1        -- ignore start-lap movements
),
driver_pit_laps AS (
    -- every lap in which the driver makes a pit-stop
    SELECT ps."race_id",
           ps."driver_id",
           ps."lap"
    FROM   "pit_stops" ps
    GROUP  BY ps."race_id", ps."driver_id", ps."lap"
),
filtered_positions AS (
    -- remove laps that coincide with the driver's own pit entry/exit
    SELECT rp.*
    FROM   race_positions rp
    LEFT   JOIN driver_pit_laps dpl
           ON  rp."race_id"  = dpl."race_id"
           AND rp."driver_id"= dpl."driver_id"
           AND rp."lap"      = dpl."lap"
    WHERE  dpl."lap" IS NULL          -- keep only non-pit laps
),
pos_changes AS (
    -- lap-to-lap position delta per driver
    SELECT fp."race_id",
           fp."driver_id",
           fp."lap",
           fp."position" 
           - LAG(fp."position") OVER (PARTITION BY fp."race_id",
                                                 fp."driver_id"
                                       ORDER BY fp."lap") AS "pos_change"
    FROM   filtered_positions fp
),
driver_balance AS (
    -- count overtakes vs. times being overtaken
    SELECT pc."driver_id",
           SUM(CASE WHEN pc."pos_change" > 0 THEN 1 ELSE 0 END) AS "times_overtaken",
           SUM(CASE WHEN pc."pos_change" < 0 THEN 1 ELSE 0 END) AS "times_overtake"
    FROM   pos_changes pc
    WHERE  pc."pos_change" <> 0
    GROUP  BY pc."driver_id"
    HAVING "times_overtaken" > "times_overtake"
)
SELECT DISTINCT de."full_name"
FROM   driver_balance db
JOIN   "drivers_ext" de
  ON   db."driver_id" = de."driver_id"
ORDER  BY de."full_name";
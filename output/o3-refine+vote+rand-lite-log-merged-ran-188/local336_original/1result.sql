WITH
/* ----------------------------------------------------------
   1)  grid‑to‑lap‑1 movements  →  start‑related overtakes
----------------------------------------------------------- */
start_vs_lap1 AS (
    SELECT  lp0."race_id",
            lp0."driver_id",
            lp0."position"  AS grid_pos,
            lp1."position"  AS lap1_pos
    FROM    "lap_positions" lp0
    JOIN    "lap_positions" lp1
           ON lp1."race_id"   = lp0."race_id"
          AND lp1."driver_id" = lp0."driver_id"
          AND lp1."lap"       = 1
    WHERE   lp0."lap" = 0
),
start_related_overtakes AS (
    SELECT COUNT(*) AS cnt
    FROM   start_vs_lap1
    WHERE  lap1_pos < grid_pos              -- gained positions between grid and lap‑1
),

/* ----------------------------------------------------------
   2)  lap‑to‑lap movements inside the first five race laps
----------------------------------------------------------- */
lap_to_lap_changes AS (
    SELECT  cur."race_id",
            cur."driver_id",
            cur."lap",
            prv."position" AS prev_pos,
            cur."position" AS curr_pos
    FROM    "lap_positions" cur
    JOIN    "lap_positions" prv
           ON prv."race_id"   = cur."race_id"
          AND prv."driver_id" = cur."driver_id"
          AND prv."lap"       = cur."lap" - 1
    WHERE   cur."lap" BETWEEN 1 AND 5
),
total_overtakes AS (
    SELECT COUNT(*) AS cnt
    FROM   lap_to_lap_changes
    WHERE  curr_pos < prev_pos             -- driver gained positions vs. previous lap
),

/* ----------------------------------------------------------
   3)  standard on‑track passes
       (all lap‑to‑lap overtakes minus the start‑related ones)
----------------------------------------------------------- */
standard_passes AS (
    SELECT (t.cnt - s.cnt) AS cnt
    FROM   total_overtakes t
    CROSS  JOIN start_related_overtakes s
),

/* ----------------------------------------------------------
   4)  retirements and pit‑stops within laps 1‑5
----------------------------------------------------------- */
early_retirements AS (
    SELECT COUNT(*) AS cnt
    FROM   "retirements"
    WHERE  "lap" <= 5
),
early_pit_stops AS (
    SELECT COUNT(*) AS cnt
    FROM   "pit_stops"
    WHERE  "lap" <= 5
)

/* ----------------------------------------------------------
   5)  final result
----------------------------------------------------------- */
SELECT
    er.cnt AS retirement_overtakes,
    ep.cnt AS pit_stop_overtakes,
    sro.cnt AS start_related_overtakes,
    sp.cnt AS standard_on_track_overtakes
FROM start_related_overtakes sro
CROSS JOIN standard_passes     sp
CROSS JOIN early_retirements   er
CROSS JOIN early_pit_stops     ep;
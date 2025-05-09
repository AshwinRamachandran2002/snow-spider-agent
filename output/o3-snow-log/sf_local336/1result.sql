/* ------------------------------------------------------------------
   OVERTAKES DURING THE FIRST FIVE LAPS – COUNTS BY CATEGORY
   ------------------------------------------------------------------
   R : gained places because another driver retired on that lap
   P : gained places because another driver pitted (lap-in / lap-out)
   S : gained places on the first racing lap (within two-grid window)
   T : “normal” on-track passes (all gains that are not R / P / S)
------------------------------------------------------------------- */

WITH
/* -----------------------------------------------------------------
   1.  Positions for laps 0-5
       – lap 0 comes from the starting grid (“RESULTS”.grid)
------------------------------------------------------------------ */
grid_positions AS (          -- lap-0 (grid)
    SELECT  "race_id",
            "driver_id",
            0              AS "lap",
            "grid"         AS "position"
    FROM    F1.F1.RESULTS
    WHERE   "grid" IS NOT NULL
),
race_positions AS (          -- lap-0 … lap-5
    SELECT * FROM grid_positions
    UNION ALL
    SELECT  "race_id",
            "driver_id",
            "lap",
            "position"
    FROM    F1.F1.LAP_POSITIONS
    WHERE   "lap" BETWEEN 1 AND 5
),

/* -----------------------------------------------------------------
   2.  Position changes (lap-1 → lap)
------------------------------------------------------------------ */
pos_change AS (
    SELECT
        "race_id",
        "driver_id",
        "lap",
        "position",
        LAG("position") OVER (PARTITION BY "race_id","driver_id"
                              ORDER BY "lap")   AS "prev_pos"
    FROM   race_positions
    WHERE  "lap" BETWEEN 1 AND 5                -- only laps we analyse
),
total_overtakes AS (         -- every positive position gain = an overtake
    SELECT  SUM("prev_pos" - "position") AS total_cnt
    FROM    pos_change
    WHERE   "prev_pos" > "position"
),

/* -----------------------------------------------------------------
   3.  Start-lap (S) overtakes  – lap 1, grid difference ≤ 2
------------------------------------------------------------------ */
start_overtakes AS (
    SELECT  SUM(r."grid" - lp."position") AS start_cnt
    FROM    F1.F1.RESULTS       r
    JOIN    F1.F1.LAP_POSITIONS lp
           ON lp."race_id"  = r."race_id"
          AND lp."driver_id" = r."driver_id"
          AND lp."lap"       = 1
    WHERE   (r."grid" - lp."position") BETWEEN 1 AND 2
),

/* -----------------------------------------------------------------
   4.  Retirement (R) – driver retires on that lap
------------------------------------------------------------------ */
retire_events AS (
    SELECT  re."race_id",
            re."lap",
            lp."position"
    FROM    F1.F1.RETIREMENTS   re
    JOIN    F1.F1.LAP_POSITIONS lp
           ON lp."race_id"  = re."race_id"
          AND lp."driver_id" = re."driver_id"
          AND lp."lap"       = re."lap"
    WHERE   re."lap" BETWEEN 1 AND 5
),
field_sizes AS (             -- field size on each (race,lap)
    SELECT  "race_id",
            "lap",
            COUNT(*) AS field_sz
    FROM    F1.F1.LAP_POSITIONS
    WHERE   "lap" BETWEEN 1 AND 5
    GROUP BY "race_id","lap"
),
retire_overtakes AS (
    /* each retirement gives every car behind +1 place  */
    SELECT  SUM(fs.field_sz - ev."position") AS retire_cnt
    FROM    retire_events  ev
    JOIN    field_sizes    fs
           ON fs."race_id" = ev."race_id"
          AND fs."lap"     = ev."lap"
),

/* -----------------------------------------------------------------
   5.  Pit-stop (P) – driver pits on lap 1-5
------------------------------------------------------------------ */
pit_moves AS (
    SELECT  ps."race_id",
            ps."driver_id",
            ps."lap"                 AS pit_lap,
            lp_in."position"         AS pos_before,
            lp_out."position"        AS pos_after
    FROM    F1.F1.PIT_STOPS      ps
    JOIN    F1.F1.LAP_POSITIONS  lp_in
           ON lp_in."race_id"   = ps."race_id"
          AND lp_in."driver_id" = ps."driver_id"
          AND lp_in."lap"       = ps."lap"
    JOIN    F1.F1.LAP_POSITIONS  lp_out
           ON lp_out."race_id"   = ps."race_id"
          AND lp_out."driver_id" = ps."driver_id"
          AND lp_out."lap"       = ps."lap" + 1         -- first lap out
    WHERE   ps."lap" BETWEEN 1 AND 5
),
pit_overtakes AS (
    /* places gained by other drivers = places lost by the pitting driver */
    SELECT  SUM(pos_after - pos_before) AS pit_cnt
    FROM    pit_moves
    WHERE   pos_after > pos_before
),

/* -----------------------------------------------------------------
   6.  Gather the four categories
------------------------------------------------------------------ */
totals AS (
    SELECT
        COALESCE((SELECT retire_cnt FROM retire_overtakes),0) AS R,
        COALESCE((SELECT pit_cnt    FROM pit_overtakes   ),0) AS P,
        COALESCE((SELECT start_cnt  FROM start_overtakes ),0) AS S,
        /* Track passes = all gains minus R / P / S  */
        COALESCE((SELECT total_cnt  FROM total_overtakes ),0)
        - COALESCE((SELECT retire_cnt FROM retire_overtakes),0)
        - COALESCE((SELECT pit_cnt    FROM pit_overtakes   ),0)
        - COALESCE((SELECT start_cnt  FROM start_overtakes ),0) AS T
)

/* -----------------------------------------------------------------
   7.  Final result
------------------------------------------------------------------ */
SELECT 'Retirements' AS "category", R AS "overtake_count" FROM totals
UNION ALL
SELECT 'Pit Stops',    P FROM totals
UNION ALL
SELECT 'Start',        S FROM totals
UNION ALL
SELECT 'On-Track',     T FROM totals
ORDER BY "category";
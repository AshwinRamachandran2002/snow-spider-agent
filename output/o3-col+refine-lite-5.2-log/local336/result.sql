/*  Count, for a single event, the number of overtakes that happened in the
    first five laps, broken down into the four requested categories.

    The event chosen (CTE chosen_race) is simply the first race that has both
    lap‑by‑lap position data AND at least one pit‑stop recorded in laps 1‑5,
    guaranteeing that every category can be evaluated consistently.
*/
WITH chosen_race AS (          -- pick one race that has the necessary data
    SELECT ps."race_id"
    FROM   "pit_stops" ps
    JOIN   "lap_positions" lp USING ("race_id")
    WHERE  ps."lap" BETWEEN 1 AND 5
    LIMIT  1
),

/* 1) Start‑related overtakes: drivers whose position improved from the grid
      (lap 0) to the first racing lap (lap 1).                               */
start_overtakes AS (
    SELECT COUNT(*) AS cnt
    FROM   (
        SELECT lp0."driver_id"
        FROM   "lap_positions" lp0                 -- lap 0 (grid)
        JOIN   "lap_positions" lp1                 -- lap 1
               ON lp1."race_id"   = lp0."race_id"
              AND lp1."driver_id" = lp0."driver_id"
              AND lp1."lap"       = 1
        JOIN   chosen_race cr ON cr."race_id" = lp0."race_id"
        WHERE  lp0."lap" = 0
          AND  lp1."position" < lp0."position"     -- improvement
    )
),

/* 2) Retirements within the first five laps.  Each retirement is counted
      as one “overtake” event of this category.                              */
retirement_overtakes AS (
    SELECT COUNT(*) AS cnt
    FROM   "retirements" r
    JOIN   chosen_race  cr ON cr."race_id" = r."race_id"
    WHERE  r."lap" <= 5
),

/* 3) Pit‑stop events in laps 1‑5.  Each stop is treated as a pit‑stop
      “overtake” opportunity.                                                */
pit_stop_overtakes AS (
    SELECT COUNT(*) AS cnt
    FROM   "pit_stops" ps
    JOIN   chosen_race cr ON cr."race_id" = ps."race_id"
    WHERE  ps."lap" BETWEEN 1 AND 5
),

/* 4) Standard on‑track passes: lap‑to‑lap position gains in laps 1‑5,
      excluding any driver who pitted in that window (so we don’t mix these
      with pit‑stop‑related position changes).                               */
standard_passes AS (
    -- positions for the five‑lap window
    WITH pos AS (
        SELECT lp."driver_id", lp."lap", lp."position"
        FROM   "lap_positions" lp, chosen_race cr
        WHERE  lp."race_id" = cr."race_id"
          AND  lp."lap" BETWEEN 1 AND 5
    ),
    deltas AS (                         -- compare successive laps
        SELECT p1."driver_id",
               p1."lap",
               p0."position" AS prev_pos,
               p1."position" AS curr_pos
        FROM   pos p1
        JOIN   pos p0
               ON p0."driver_id" = p1."driver_id"
              AND p0."lap"       = p1."lap" - 1
    )
    SELECT COUNT(*) AS cnt
    FROM   deltas d
    WHERE  (d.prev_pos - d.curr_pos) > 0       -- gained positions
      AND  d."driver_id" NOT IN (              -- exclude pitters
              SELECT DISTINCT ps."driver_id"
              FROM   "pit_stops" ps
              JOIN   chosen_race cr ON cr."race_id" = ps."race_id"
              WHERE  ps."lap" BETWEEN 1 AND 5
          )
)
-- Final result: one row, four columns
SELECT
    (SELECT cnt FROM retirement_overtakes)   AS retirements,
    (SELECT cnt FROM pit_stop_overtakes)     AS pit_stop_overtakes,
    (SELECT cnt FROM start_overtakes)        AS start_related_overtakes,
    (SELECT cnt FROM standard_passes)        AS standard_on_track_passes;
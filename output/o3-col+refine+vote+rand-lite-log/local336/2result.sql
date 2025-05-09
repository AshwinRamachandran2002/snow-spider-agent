WITH
-- 1.  Grid vs. end-lap-1 to find start-overtakes
start_overtakes AS (
    SELECT COUNT(*) AS cnt
    FROM (
        SELECT g."driver_id"
        FROM   "lap_positions" AS g
        JOIN   "lap_positions" AS l1
               ON  l1."race_id"  = g."race_id"
               AND l1."driver_id"= g."driver_id"
               AND l1."lap"      = 1
               AND l1."lap_type" = 'Race'
        WHERE  g."race_id" = 1          -- <<-- pick the race here
          AND  g."lap"     = 0          -- grid
          AND  l1."position" < g."position"   -- improved from grid
    )
),

-- 2.  Pit-stop occurrences inside laps 1-5
pit_stop_overtakes AS (
    SELECT COUNT(*) AS cnt
    FROM   "pit_stops"
    WHERE  "race_id" = 1
      AND  "lap" BETWEEN 1 AND 5
),

-- 3.  Retirements inside laps 1-5
retirement_overtakes AS (
    SELECT COUNT(*) AS cnt
    FROM   "retirements"
    WHERE  "race_id" = 1
      AND  "lap" BETWEEN 1 AND 5
),

-- 4.  ‘Pure’ on-track passes between consecutive race laps
std_passes AS (
    SELECT COUNT(*) AS cnt
    FROM (
        SELECT 1
        FROM   "lap_positions" AS cur
        JOIN   "lap_positions" AS prev
               ON  prev."race_id"   = cur."race_id"
               AND prev."driver_id" = cur."driver_id"
               AND prev."lap"       = cur."lap" - 1
        WHERE  cur."race_id" = 1
          AND  cur."lap" BETWEEN 1 AND 5
          AND  cur."lap_type"  = 'Race'
          AND  prev."lap_type" = 'Race'
          AND  cur."position"  < prev."position"        -- gained places
          -- exclude laps where the driver pitted
          AND  NOT EXISTS (
                 SELECT 1
                 FROM   "pit_stops" p
                 WHERE  p."race_id"  = cur."race_id"
                   AND  p."driver_id"= cur."driver_id"
                   AND  p."lap" IN (cur."lap", prev."lap")
               )
          -- exclude gains caused by a retirement on that lap
          AND  NOT EXISTS (
                 SELECT 1
                 FROM   "retirements" r
                 WHERE  r."race_id" = cur."race_id"
                   AND  r."lap"     = cur."lap"
               )
    )
)

-- 5.  Return all four categories side-by-side
SELECT  r.cnt  AS retirement_overtakes,
        p.cnt  AS pit_stop_overtakes,
        s.cnt  AS start_overtakes,
        o.cnt  AS standard_on_track_passes
FROM    retirement_overtakes  r,
        pit_stop_overtakes    p,
        start_overtakes       s,
        std_passes            o;
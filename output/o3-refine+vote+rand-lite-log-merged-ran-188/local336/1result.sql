WITH grid AS (
    SELECT "race_id",
           "driver_id",
           "position" AS grid_pos
    FROM   "lap_positions"
    WHERE  "lap_type" LIKE 'Starting%'
),
race_laps AS (
    SELECT "race_id",
           "driver_id",
           "lap",
           "position"
    FROM   "lap_positions"
    WHERE  "lap_type" = 'Race'
      AND  "lap" BETWEEN 1 AND 5
),
pos_changes AS (
    SELECT rl.*,
           LAG("position") OVER (PARTITION BY rl."race_id", rl."driver_id"
                                 ORDER BY rl."lap") AS prev_pos,
           g.grid_pos
    FROM   race_laps rl
    JOIN   grid g USING ("race_id","driver_id")
),
gains AS (        -- every forward-move in laps 1-5
    SELECT "race_id",
           "driver_id",
           "lap",
           CASE
                WHEN "lap" = 1 AND "position" < grid_pos THEN 'start'
                ELSE 'provisional'
           END AS base_cat
    FROM   pos_changes
    WHERE  (("lap" = 1  AND "position" < grid_pos)   -- grid → end-lap-1 gain
         OR ("lap" > 1  AND "position" < prev_pos))  -- later lap-to-lap gain
),
ret_laps AS (     -- laps in which at least one retirement happened
    SELECT DISTINCT "race_id", "lap"
    FROM   "retirements"
    WHERE  "lap" BETWEEN 1 AND 5
),
pit_laps AS (     -- laps in which at least one pit-stop happened
    SELECT DISTINCT "race_id", "lap"
    FROM   "pit_stops"
    WHERE  "lap" BETWEEN 1 AND 5
),
classified AS (
    SELECT g.*,
           CASE
                WHEN EXISTS (SELECT 1
                             FROM   ret_laps r
                             WHERE  r."race_id" = g."race_id"
                               AND  r."lap"      = g."lap")        THEN 'retirement'
                WHEN EXISTS (SELECT 1
                             FROM   pit_laps p
                             WHERE  p."race_id" = g."race_id"
                               AND  p."lap"      = g."lap")        THEN 'pit_stop'
                WHEN g.base_cat = 'start'                          THEN 'start'
                ELSE 'on_track'
           END AS category
    FROM   gains g
)
SELECT category,
       COUNT(*) AS overtakes
FROM   classified
GROUP  BY category
ORDER  BY category;
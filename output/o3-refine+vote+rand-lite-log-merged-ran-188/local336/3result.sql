WITH
start_overtakes AS (             -- positions gained between grid-lap(0) and lap-1
    SELECT COALESCE(
           SUM(CASE WHEN lp0."position" - lp1."position" > 0
                    THEN lp0."position" - lp1."position" END),0) AS cnt
    FROM   "lap_positions" lp0
    JOIN   "lap_positions" lp1
           ON lp0."race_id"  = lp1."race_id"
          AND lp0."driver_id"= lp1."driver_id"
    WHERE  lp0."race_id" = 1
      AND  lp0."lap"  = 0
      AND  lp1."lap"  = 1
),
early_pits AS (                  -- every pit stop in laps 1-5
    SELECT DISTINCT "driver_id","lap"
    FROM   "pit_stops"
    WHERE  "race_id" = 1
      AND  "lap" BETWEEN 1 AND 5
),
pit_overtakes AS (               -- places gained when rivals pitted
    SELECT COALESCE(
           SUM(CASE WHEN after."position" - before."position" > 0
                    THEN after."position" - before."position" END),0) AS cnt
    FROM   early_pits ep
    JOIN   "lap_positions" before
           ON before."race_id"  = 1
          AND before."driver_id"= ep."driver_id"
          AND before."lap"      = ep."lap" - 1
    JOIN   "lap_positions" after
           ON after."race_id"   = 1
          AND after."driver_id" = ep."driver_id"
          AND after."lap"       = ep."lap"
),
early_ret AS (                   -- retirements in laps 1-5
    SELECT "driver_id","lap"
    FROM   "retirements"
    WHERE  "race_id" = 1
      AND  "lap" BETWEEN 1 AND 5
),
retirement_overtakes AS (        -- places gained when rivals retired
    SELECT COALESCE(
           SUM( (SELECT COUNT(*)
                 FROM   "lap_positions" lp
                 WHERE  lp."race_id" = 1
                   AND  lp."lap"     = er."lap"
                   AND  lp."position" >
                        (SELECT lp2."position"
                         FROM   "lap_positions" lp2
                         WHERE  lp2."race_id"  = 1
                           AND  lp2."driver_id"= er."driver_id"
                           AND  lp2."lap"      = er."lap") ) ),0) AS cnt
    FROM   early_ret er
),
total_position_gains AS (        -- all positive position changes between laps
    SELECT COALESCE(
           SUM(CASE WHEN prev."position" - curr."position" > 0
                    THEN prev."position" - curr."position" END),0) AS cnt
    FROM   "lap_positions" curr
    JOIN   "lap_positions" prev
           ON curr."race_id"  = prev."race_id"
          AND curr."driver_id"= prev."driver_id"
          AND curr."lap"      = prev."lap" + 1
    WHERE  curr."race_id" = 1
      AND  curr."lap" BETWEEN 1 AND 5
)

SELECT
       (SELECT cnt FROM retirement_overtakes)                       AS "Retirements",
       (SELECT cnt FROM pit_overtakes)                              AS "Pit-stops",
       (SELECT cnt FROM start_overtakes)                            AS "Start-related",
       ( (SELECT cnt FROM total_position_gains)
         - (SELECT cnt FROM start_overtakes)
         - (SELECT cnt FROM pit_overtakes)
         - (SELECT cnt FROM retirement_overtakes) )                 AS "Standard on-track";
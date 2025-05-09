/*  OVERTAKES INSIDE THE FIRST 5 LAPS – SPLIT BY CATEGORY  */
WITH
/* 1. raw position changes between consecutive racing laps 1-5 */
pos_changes AS (
    SELECT  lp1."race_id",
            SUM(CASE WHEN lp2."position" <> lp1."position" THEN 1 ELSE 0 END)
                   AS "pos_changes_laps1_5"
    FROM    "lap_positions" AS lp1
    JOIN    "lap_positions" AS lp2
           ON lp2."race_id"   = lp1."race_id"
          AND lp2."driver_id" = lp1."driver_id"
          AND lp2."lap"       = lp1."lap" + 1
    WHERE   lp1."lap_type" = 'Race'
      AND   lp2."lap_type" = 'Race'
      AND   lp1."lap" BETWEEN 1 AND 4          -- so that lp1+1 ≤ 5
    GROUP BY lp1."race_id"
),

/* 2. retirements that happened on laps 1-5 */
retirements_first5 AS (
    SELECT  "race_id",
            COUNT(*) AS "retirements_first5"
    FROM    "retirements"
    WHERE   "lap" BETWEEN 1 AND 5
    GROUP BY "race_id"
),

/* 3. pit-stops carried out on laps 1-5 */
pitstops_first5 AS (
    SELECT  "race_id",
            COUNT(*) AS "pitstops_first5"
    FROM    "pit_stops"
    WHERE   "lap" BETWEEN 1 AND 5
    GROUP BY "race_id"
),

/* 4. position changes between the grid (lap 0) and lap-1  →  start-related */
start_related AS (
    SELECT  lp0."race_id",
            COUNT(*) AS "start_related_overtakes"
    FROM    "lap_positions" AS lp0
    JOIN    "lap_positions" AS lp1
           ON lp1."race_id"   = lp0."race_id"
          AND lp1."driver_id" = lp0."driver_id"
    WHERE   lp0."lap"       = 0
      AND   lp1."lap"       = 1
      AND   lp1."position" <> lp0."position"
    GROUP BY lp0."race_id"
)

/* 5. combine the four components and derive “standard on-track passes” */
SELECT  pc."race_id",
        COALESCE(rt."retirements_first5",0)        AS "retirements",
        COALESCE(ps."pitstops_first5",0)           AS "pit_stops",
        COALESCE(st."start_related_overtakes",0)   AS "start_related_overtakes",
        ( pc."pos_changes_laps1_5"
          - COALESCE(rt."retirements_first5",0)
          - COALESCE(ps."pitstops_first5",0)
          - COALESCE(st."start_related_overtakes",0)
        )                                          AS "standard_ontrack_passes"
FROM     pos_changes          AS pc
LEFT JOIN retirements_first5  AS rt ON rt."race_id" = pc."race_id"
LEFT JOIN pitstops_first5     AS ps ON ps."race_id" = pc."race_id"
LEFT JOIN start_related       AS st ON st."race_id" = pc."race_id"
ORDER BY pc."race_id";
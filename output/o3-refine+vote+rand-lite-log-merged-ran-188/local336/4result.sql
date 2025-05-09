WITH
    race AS (                               -- choose the race to analyse
        SELECT 18 AS race_id                -- 2009 Australian GP
    ),

    /* 1) overtakes caused by retirements (laps ≤ 5) */
    ret AS (
        SELECT COUNT(*) AS retirements
        FROM   "retirements"  r
        JOIN   race           ON r."race_id" = race.race_id
        WHERE  r."lap" <= 5
    ),

    /* 2) position changes due to pit-stops (laps ≤ 5) */
    pit AS (
        SELECT COUNT(*) AS pit_stops
        FROM   "pit_stops"  p
        JOIN   race         ON p."race_id" = race.race_id
        WHERE  p."lap" <= 5
    ),

    /* 3) start-related gains: grid → lap 1 */
    start AS (
        SELECT SUM(CASE WHEN lp."position" < res."grid" THEN 1 ELSE 0 END)
               AS start_related
        FROM   race
        JOIN   "results"        res ON res."race_id" = race.race_id
        JOIN   "lap_positions"  lp
               ON lp."race_id"   = res."race_id"
              AND lp."driver_id" = res."driver_id"
        WHERE  lp."lap" = 1
    ),

    /* 4) all lap-to-lap position gains from lap 1 to lap 5 */
    total AS (
        SELECT SUM(
                   CASE WHEN lp1."position" < lp0."position" THEN 1 ELSE 0 END
               ) AS total_gains
        FROM   race
        JOIN   "lap_positions" lp1
               ON lp1."race_id" = race.race_id
        JOIN   "lap_positions" lp0
               ON lp0."race_id"  = lp1."race_id"
              AND lp0."driver_id" = lp1."driver_id"
              AND lp0."lap"       = lp1."lap" - 1
        WHERE  lp1."lap" BETWEEN 1 AND 5
    )

SELECT
       ret.retirements                                            AS "retirements",
       pit.pit_stops                                              AS "pit_stops",
       start.start_related                                        AS "start_related_overtakes",
       total.total_gains
       - ret.retirements
       - pit.pit_stops
       - start.start_related                                      AS "standard_ontrack_passes"
FROM   ret, pit, start, total;
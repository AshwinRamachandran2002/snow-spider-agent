WITH
    -- Races that have complete pit–stop information
    "races_with_pit" AS (
        SELECT "race_id"
        FROM   "races_ext"
        WHERE  "is_pit_data_available" = 1
    ),

    /* ------------------------------------------------------------------
       1) GRID / RACE-START OVERTAKES  (lap 0  → lap 1)
    ------------------------------------------------------------------ */
    "race_start" AS (
        SELECT
               SUM( lp0."position" - lp1."position" ) AS "cnt"
        FROM   "lap_positions" lp0
        JOIN   "lap_positions" lp1
               ON  lp1."race_id"   = lp0."race_id"
               AND lp1."driver_id" = lp0."driver_id"
               AND lp1."lap"       = 1
        WHERE  lp0."lap"         = 0
        AND    lp0."race_id" IN (SELECT "race_id" FROM "races_with_pit")
        AND    (lp0."position" - lp1."position") > 0          -- places gained
    ),

    /* ------------------------------------------------------------------
       2) OVERTAKES CAUSED BY A RIVAL ENTERING THE PITS  ( “pit-in” )
    ------------------------------------------------------------------ */
    "pit_in" AS (
        SELECT
               SUM( lp_prev."position" - lp_curr."position" ) AS "cnt"
        FROM   "pit_stops"     ps
        JOIN   "races_with_pit" r  ON r."race_id"   = ps."race_id"
        JOIN   "lap_positions" lp_prev
               ON  lp_prev."race_id" = ps."race_id"
               AND lp_prev."lap"     = ps."lap" - 1           -- lap before pit-in
        JOIN   "lap_positions" lp_curr
               ON  lp_curr."race_id" = ps."race_id"
               AND lp_curr."driver_id" = lp_prev."driver_id"
               AND lp_curr."lap"     = ps."lap"               -- lap of pit-in
        WHERE  lp_prev."driver_id" <> ps."driver_id"           -- exclude pitting car
        AND    (lp_prev."position" - lp_curr."position") > 0   -- beneficiary gained
    ),

    /* ------------------------------------------------------------------
       3) OVERTAKES CAUSED BY A RETIREMENT ON THE LAP
    ------------------------------------------------------------------ */
    "retirement" AS (
        SELECT
               SUM( lp_prev."position" - lp_curr."position" ) AS "cnt"
        FROM   "retirements"  rt
        JOIN   "races_with_pit" r  ON r."race_id"   = rt."race_id"
        JOIN   "lap_positions" lp_prev
               ON  lp_prev."race_id" = rt."race_id"
               AND lp_prev."lap"     = rt."lap" - 1
        JOIN   "lap_positions" lp_curr
               ON  lp_curr."race_id" = rt."race_id"
               AND lp_curr."driver_id" = lp_prev."driver_id"
               AND lp_curr."lap"     = rt."lap"
        WHERE  lp_prev."driver_id" <> rt."driver_id"           -- exclude retiring car
        AND    (lp_prev."position" - lp_curr."position") > 0   -- beneficiary gained
    ),

    /* ------------------------------------------------------------------
       4) NORMAL ON-TRACK OVERTAKES  
          (successive laps, no pit-in / retirement for the beneficiary)
    ------------------------------------------------------------------ */
    "on_track" AS (
        SELECT
               SUM( s."pos_prev" - s."pos_curr" ) AS "cnt"
        FROM (
                SELECT
                       lp_curr."race_id",
                       lp_curr."lap"          AS "curr_lap",
                       lp_curr."driver_id",
                       lp_prev."position"     AS "pos_prev",
                       lp_curr."position"     AS "pos_curr"
                FROM   "lap_positions" lp_curr
                JOIN   "lap_positions" lp_prev
                       ON  lp_curr."race_id"   = lp_prev."race_id"
                       AND lp_curr."driver_id" = lp_prev."driver_id"
                       AND lp_curr."lap"       = lp_prev."lap" + 1
                WHERE  lp_curr."race_id" IN (SELECT "race_id" FROM "races_with_pit")
              ) s
        LEFT  JOIN "pit_stops"  ps
               ON  ps."race_id"   = s."race_id"
               AND ps."driver_id" = s."driver_id"
               AND ps."lap"       = s."curr_lap"          -- beneficiary pitting? exclude
        LEFT  JOIN "retirements" rt
               ON  rt."race_id"   = s."race_id"
               AND rt."driver_id" = s."driver_id"
               AND rt."lap"       = s."curr_lap"          -- beneficiary retiring? exclude
        WHERE (s."pos_prev" - s."pos_curr") > 0            -- positions gained
          AND s."curr_lap" > 1                             -- skip race-start lap
          AND ps."driver_id" IS NULL                       -- not a pit-in/out for him
          AND rt."driver_id" IS NULL                       -- not retiring
    ),

    /* ------------------------------------------------------------------
       Combine the four categories
    ------------------------------------------------------------------ */
    "overtake_totals" AS (
        SELECT 'Race Start'  AS "overtake_type", COALESCE( (SELECT "cnt" FROM "race_start") , 0 ) AS "overtake_count"
        UNION ALL
        SELECT 'Pit Stop'    AS "overtake_type", COALESCE( (SELECT "cnt" FROM "pit_in")    , 0 )
        UNION ALL
        SELECT 'Retirement'  AS "overtake_type", COALESCE( (SELECT "cnt" FROM "retirement"), 0 )
        UNION ALL
        SELECT 'On-track'    AS "overtake_type", COALESCE( (SELECT "cnt" FROM "on_track")  , 0 )
    )

SELECT *
FROM   "overtake_totals";
SELECT
  /* 1. Positions gifted by retirements in laps ≤ 5           */
  (SELECT COUNT(*) 
     FROM "retirements"
    WHERE "race_id" = 1 
      AND "lap"     <= 5)                                      AS "retirement_overtakes",

  /* 2. Positions gained because rivals pitted in laps ≤ 5     */
  (SELECT COUNT(*) 
     FROM "pit_stops"
    WHERE "race_id" = 1
      AND "lap"     <= 5)                                      AS "pit_stop_overtakes",

  /* 3. Start-related gains: grid (lap 0) → first race lap 1   */
  (SELECT COUNT(*) 
     FROM "lap_positions" lp0
     JOIN "lap_positions" lp1
       ON lp0."race_id"   = lp1."race_id"
      AND lp0."driver_id" = lp1."driver_id"
    WHERE lp0."race_id" = 1
      AND lp0."lap"      = 0          -- grid
      AND lp1."lap"      = 1          -- first full lap
      AND lp1."position" < lp0."position")                     AS "start_related_overtakes",

  /* 4. Standard on-track passes between consecutive laps 1-5  */
  (SELECT COUNT(*)
     FROM "lap_positions" lp_prev
     JOIN "lap_positions" lp_curr
       ON lp_prev."race_id"   = lp_curr."race_id"
      AND lp_prev."driver_id" = lp_curr."driver_id"
      AND lp_curr."lap"       = lp_prev."lap" + 1
    WHERE lp_prev."race_id" = 1
      AND lp_prev."lap" BETWEEN 1 AND 4   -- ensures curr 2-5
      AND lp_curr."position" < lp_prev."position")             AS "standard_overtakes";
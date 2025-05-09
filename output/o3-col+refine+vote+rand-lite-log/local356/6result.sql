WITH lap_changes AS (
    /* 1. Compare each driver’s position on consecutive race laps
          (ignore first-lap grid movement). */
    SELECT  lp1."race_id",
            lp1."driver_id",
            lp1."lap",
            lp1."position" AS "new_pos",
            lp0."position" AS "old_pos"
    FROM    "lap_positions" AS lp1
    JOIN    "lap_positions" AS lp0
             ON lp1."race_id"   = lp0."race_id"
            AND lp1."driver_id" = lp0."driver_id"
            AND lp1."lap"       = lp0."lap" + 1
    WHERE   lp1."lap"        > 1              -- exclude start movements
      AND   lp1."lap_type"   = 'Race'         -- race laps only
      AND   lp0."lap_type"   = 'Race'
),
filtered_changes AS (
    /* 2. Discard position changes on pit-stop laps and after retirement. */
    SELECT  lc.*
    FROM    lap_changes lc
    LEFT JOIN "pit_stops"   ps  ON lc."race_id" = ps."race_id"
                                AND lc."driver_id" = ps."driver_id"
                                AND lc."lap" = ps."lap"
    LEFT JOIN "retirements" rt  ON lc."race_id" = rt."race_id"
                                AND lc."driver_id" = rt."driver_id"
                                AND lc."lap" >= rt."lap"
    WHERE   ps."driver_id" IS NULL   -- omit pit-stop exchanges
      AND   rt."driver_id" IS NULL   -- omit laps after retirement
),
overtake_totals AS (
    /* 3. Count overtakes made vs. times overtaken per driver. */
    SELECT  "driver_id",
            SUM(CASE WHEN "new_pos" < "old_pos" THEN 1 ELSE 0 END) AS "overtakes",
            SUM(CASE WHEN "new_pos" > "old_pos" THEN 1 ELSE 0 END) AS "times_overtaken"
    FROM    filtered_changes
    GROUP BY "driver_id"
)
SELECT  d."full_name"
FROM    overtake_totals ot
JOIN    "drivers_ext" d ON d."driver_id" = ot."driver_id"
WHERE   ot."times_overtaken" > ot."overtakes"   -- more passed than passes
ORDER BY d."full_name";
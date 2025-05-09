WITH positions AS (
    SELECT "race_id", "lap", "driver_id", "position"
    FROM F1.F1.LAP_POSITIONS
),

driver_positions AS (
    SELECT "race_id", "driver_id", "lap", "position",
           LEAD("position") OVER (PARTITION BY "race_id", "driver_id" ORDER BY "lap") AS "next_position",
           "lap" + 1 AS "next_lap"
    FROM positions
),

overtakes AS (
    SELECT dp1."race_id",
           dp1."lap",
           dp1."driver_id" AS "driver_a",
           dp2."driver_id" AS "driver_b",
           dp1."position" AS "position_a_prev",
           dp2."position" AS "position_b_prev",
           dp1."next_position" AS "position_a_next",
           dp2."next_position" AS "position_b_next",
           dp1."next_lap"
    FROM driver_positions dp1
    JOIN driver_positions dp2
      ON dp1."race_id" = dp2."race_id"
     AND dp1."lap" = dp2."lap"
     AND dp1."driver_id" <> dp2."driver_id"
    WHERE dp1."next_position" IS NOT NULL
      AND dp2."next_position" IS NOT NULL
      AND dp1."position" > dp2."position"
      AND dp1."next_position" < dp2."next_position"
),

overtake_events AS (
    SELECT o.*,
           r."lap" AS "retirement_lap",
           p_entry."lap" AS "pit_entry_lap",
           p_exit."lap" AS "pit_exit_lap",
           g_a."grid" AS "grid_a",
           g_b."grid" AS "grid_b",
           CASE
               WHEN r."lap" IS NOT NULL THEN 'R'
               WHEN p_entry."lap" IS NOT NULL OR p_exit."lap" IS NOT NULL THEN 'P'
               WHEN o."lap" = 1 AND ABS(g_a."grid" - g_b."grid") <= 2 THEN 'S'
               ELSE 'T'
           END AS "overtake_type"
    FROM overtakes o
    LEFT JOIN F1.F1.RETIREMENTS r
      ON o."race_id" = r."race_id"
     AND o."driver_b" = r."driver_id"
     AND r."lap" = o."next_lap"
    LEFT JOIN F1.F1.PIT_STOPS p_entry
      ON o."race_id" = p_entry."race_id"
     AND o."driver_b" = p_entry."driver_id"
     AND p_entry."lap" = o."next_lap"
    LEFT JOIN F1.F1.PIT_STOPS p_exit
      ON o."race_id" = p_exit."race_id"
     AND o."driver_b" = p_exit."driver_id"
     AND p_exit."lap" = o."lap"
    LEFT JOIN F1.F1.RESULTS g_a
      ON o."race_id" = g_a."race_id"
     AND o."driver_a" = g_a."driver_id"
    LEFT JOIN F1.F1.RESULTS g_b
      ON o."race_id" = g_b."race_id"
     AND o."driver_b" = g_b."driver_id"
)

SELECT "overtake_type", COUNT(*) AS "overtake_count"
FROM overtake_events
GROUP BY "overtake_type"
ORDER BY "overtake_type";
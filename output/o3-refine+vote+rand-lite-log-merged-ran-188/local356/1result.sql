WITH pitlaps AS (
    SELECT DISTINCT "race_id", "lap"
    FROM "pit_stops"
),
retirelaps AS (
    SELECT DISTINCT "race_id", "lap"
    FROM "retirements"
),
race_positions AS (
    SELECT  lp."race_id",
            lp."driver_id",
            lp."lap",
            lp."position",
            LAG(lp."position") OVER (
                PARTITION BY lp."race_id", lp."driver_id"
                ORDER BY lp."lap"
            ) AS prev_pos
    FROM "lap_positions" lp
    WHERE lp."lap_type" = 'Race'      -- keep only actual race laps
      AND lp."lap" > 1                -- ignore first-lap start moves
),
moves AS (
    SELECT  rp."race_id",
            rp."driver_id",
            CASE
                WHEN rp.prev_pos IS NOT NULL AND rp.prev_pos > rp."position" THEN  1  -- overtook
                WHEN rp.prev_pos IS NOT NULL AND rp.prev_pos < rp."position" THEN -1  -- was overtaken
                ELSE 0
            END AS move
    FROM race_positions rp
    WHERE NOT EXISTS (SELECT 1
                      FROM pitlaps p
                      WHERE p."race_id" = rp."race_id"
                        AND p."lap"     = rp."lap")     -- exclude pit-stop laps
      AND NOT EXISTS (SELECT 1
                      FROM retirelaps r
                      WHERE r."race_id" = rp."race_id"
                        AND r."lap"     = rp."lap")     -- exclude retirement laps
),
totals AS (
    SELECT  "driver_id",
            SUM(CASE WHEN move =  1 THEN 1 ELSE 0 END) AS overtakes_made,
            SUM(CASE WHEN move = -1 THEN 1 ELSE 0 END) AS overtakes_suffered
    FROM moves
    GROUP BY "driver_id"
)
SELECT DISTINCT d."full_name"
FROM totals t
JOIN "drivers_ext" d USING ("driver_id")
WHERE t."overtakes_suffered" > t."overtakes_made";
WITH driver_positions AS (
    SELECT
        "race_id",
        "driver_id",
        "lap",
        "position"
    FROM F1.F1."LAP_POSITIONS"
),

positions_prev AS (
    SELECT
        dp1."race_id",
        dp1."driver_id",
        dp1."lap" AS "lap_current",
        dp1."position" AS "position_current",
        dp2."position" AS "position_prev"
    FROM driver_positions dp1
    JOIN driver_positions dp2
        ON dp1."race_id" = dp2."race_id"
        AND dp1."driver_id" = dp2."driver_id"
        AND dp1."lap" = dp2."lap" + 1
),

overtakes AS (
    SELECT DISTINCT
        dp1."race_id",
        dp1."lap_current",
        dp1."driver_id" AS "overtaking_driver_id",
        dp2."driver_id" AS "overtaken_driver_id",
        dp1."position_current" AS "overtaking_position",
        dp2."position_current" AS "overtaken_position",
        dp1."position_prev" AS "overtaking_prev_position",
        dp2."position_prev" AS "overtaken_prev_position"
    FROM positions_prev dp1
    JOIN positions_prev dp2
        ON dp1."race_id" = dp2."race_id"
        AND dp1."lap_current" = dp2."lap_current"
        AND dp1."driver_id" <> dp2."driver_id"
    WHERE
        dp1."position_prev" > dp2."position_prev"     -- Overtaking driver was behind on previous lap
        AND dp1."position_current" < dp2."position_current" -- Overtaking driver is ahead now
),

overtakes_classified AS (
    SELECT
        o."race_id",
        o."lap_current",
        o."overtaking_driver_id",
        o."overtaken_driver_id",
        o."overtaking_position",
        o."overtaken_position",
        CASE
            WHEN rt."driver_id" IS NOT NULL THEN 'R'   -- Retirement overtake
            WHEN ps_entry."driver_id" IS NOT NULL OR ps_exit."driver_id" IS NOT NULL THEN 'P' -- Pit overtake
            WHEN o."lap_current" = 1 
                 AND ABS(r1."grid" - r2."grid") <= 2 
                 AND r1."grid" IS NOT NULL 
                 AND r2."grid" IS NOT NULL THEN 'S' -- Start overtake
            ELSE 'T'  -- Track overtake
        END AS "overtake_type"
    FROM overtakes o
    LEFT JOIN F1.F1."RETIREMENTS" rt
        ON o."race_id" = rt."race_id"
        AND o."lap_current" = rt."lap"
        AND o."overtaken_driver_id" = rt."driver_id"
    LEFT JOIN F1.F1."PIT_STOPS" ps_entry
        ON o."race_id" = ps_entry."race_id"
        AND o."lap_current" = ps_entry."lap"
        AND o."overtaken_driver_id" = ps_entry."driver_id"
    LEFT JOIN F1.F1."PIT_STOPS" ps_exit
        ON o."race_id" = ps_exit."race_id"
        AND o."lap_current" = ps_exit."lap" + 1
        AND o."overtaken_driver_id" = ps_exit."driver_id"
    JOIN F1.F1."RESULTS" r1
        ON o."race_id" = r1."race_id"
        AND o."overtaking_driver_id" = r1."driver_id"
    JOIN F1.F1."RESULTS" r2
        ON o."race_id" = r2."race_id"
        AND o."overtaken_driver_id" = r2."driver_id"
)

SELECT "overtake_type", COUNT(*) AS "overtake_count"
FROM overtakes_classified
GROUP BY "overtake_type"
ORDER BY "overtake_type";
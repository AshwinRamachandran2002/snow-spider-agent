WITH overtakes AS (
    SELECT
        lp_current."race_id",
        lp_current."lap",
        lp_current."driver_id" AS "overtaking_driver_id",
        lp_competitor."driver_id" AS "overtaken_driver_id",
        lp_current."position" AS "overtaking_position",
        lp_current_prev."position" AS "overtaking_prev_position",
        lp_competitor."position" AS "overtaken_position",
        lp_competitor_prev."position" AS "overtaken_prev_position"
    FROM
        F1.F1."LAP_POSITIONS" lp_current
    INNER JOIN
        F1.F1."LAP_POSITIONS" lp_current_prev
        ON lp_current."race_id" = lp_current_prev."race_id"
        AND lp_current."driver_id" = lp_current_prev."driver_id"
        AND lp_current."lap" = lp_current_prev."lap" + 1
    INNER JOIN
        F1.F1."LAP_POSITIONS" lp_competitor
        ON lp_current."race_id" = lp_competitor."race_id"
        AND lp_current."lap" = lp_competitor."lap"
        AND lp_current."driver_id" <> lp_competitor."driver_id"
    INNER JOIN
        F1.F1."LAP_POSITIONS" lp_competitor_prev
        ON lp_competitor."race_id" = lp_competitor_prev."race_id"
        AND lp_competitor."driver_id" = lp_competitor_prev."driver_id"
        AND lp_competitor."lap" = lp_competitor_prev."lap" + 1
    WHERE
        lp_current_prev."position" > lp_competitor_prev."position"  -- Overtaking driver was behind
        AND lp_current."position" < lp_competitor."position"        -- Overtaking driver is now ahead
),
overtakes_classified AS (
    SELECT
        o."race_id",
        o."lap",
        o."overtaking_driver_id",
        o."overtaken_driver_id",
        CASE
            WHEN r."driver_id" IS NOT NULL THEN 'R'  -- Retirement overtake
            WHEN ps_entry."driver_id" IS NOT NULL THEN 'P'  -- Pit entry overtake
            WHEN ps_exit."driver_id" IS NOT NULL THEN 'P'   -- Pit exit overtake
            WHEN o."lap" = 1
                 AND ABS(res_ot."grid" - res_ok."grid") <= 2 THEN 'S'  -- Start overtake
            ELSE 'T'  -- Track overtake
        END AS "overtake_type"
    FROM
        overtakes o
    LEFT JOIN F1.F1."RETIREMENTS" r
        ON o."race_id" = r."race_id"
        AND o."overtaken_driver_id" = r."driver_id"
        AND o."lap" = r."lap"
    LEFT JOIN F1.F1."PIT_STOPS" ps_entry
        ON o."race_id" = ps_entry."race_id"
        AND o."overtaken_driver_id" = ps_entry."driver_id"
        AND o."lap" = ps_entry."lap"
    LEFT JOIN F1.F1."PIT_STOPS" ps_exit
        ON o."race_id" = ps_exit."race_id"
        AND o."overtaken_driver_id" = ps_exit."driver_id"
        AND o."lap" = ps_exit."lap" + 1
    LEFT JOIN F1.F1."RESULTS" res_ot
        ON o."race_id" = res_ot."race_id"
        AND o."overtaking_driver_id" = res_ot."driver_id"
    LEFT JOIN F1.F1."RESULTS" res_ok
        ON o."race_id" = res_ok."race_id"
        AND o."overtaken_driver_id" = res_ok."driver_id"
)
SELECT
    "overtake_type",
    COUNT(*) AS "overtake_count"
FROM
    overtakes_classified
GROUP BY
    "overtake_type";
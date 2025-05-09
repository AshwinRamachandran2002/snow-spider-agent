WITH positions AS (
    -- Positions at lap 0 (grid positions)
    SELECT
        r."race_id",
        r."driver_id",
        0 AS "lap",
        r."grid" AS "position"
    FROM
        "F1"."F1"."RESULTS" r
    UNION ALL
    -- Positions at laps 1 to 5 from LAP_TIMES
    SELECT
        lt."race_id",
        lt."driver_id",
        lt."lap",
        lt."position"
    FROM
        "F1"."F1"."LAP_TIMES" lt
    WHERE
        lt."lap" BETWEEN 1 AND 5
),
position_changes AS (
    SELECT
        dp1."race_id",
        dp1."driver_id",
        dp1."lap",
        dp1."position",
        dp0."position" AS "prev_position"
    FROM
        positions dp1
    JOIN
        positions dp0
    ON
        dp1."race_id" = dp0."race_id"
        AND dp1."driver_id" = dp0."driver_id"
        AND dp1."lap" = dp0."lap" + 1
    WHERE
        dp1."lap" BETWEEN 1 AND 5
),
driver_pairs AS (
    SELECT
        dp1."race_id",
        dp1."lap",
        dp1."driver_id" AS "overtaking_driver_id",
        dp1."position" AS "position_a",
        dp1."prev_position" AS "prev_position_a",
        dp2."driver_id" AS "overtaken_driver_id",
        dp2."position" AS "position_b",
        dp2."prev_position" AS "prev_position_b"
    FROM
        position_changes dp1
    JOIN
        position_changes dp2
    ON
        dp1."race_id" = dp2."race_id"
        AND dp1."lap" = dp2."lap"
        AND dp1."driver_id" <> dp2."driver_id"
    WHERE
        dp1."prev_position" > dp2."prev_position"
        AND dp1."position" < dp2."position"
),
overtakes AS (
    SELECT
        dp."race_id",
        dp."lap",
        dp."overtaking_driver_id",
        dp."overtaken_driver_id"
    FROM
        driver_pairs dp
),
overtakes_classified AS (
    SELECT
        o."race_id",
        o."lap",
        o."overtaking_driver_id",
        o."overtaken_driver_id",
        CASE
            WHEN r_ret."driver_id" IS NOT NULL THEN 'Retirements'
            WHEN ps."driver_id" IS NOT NULL THEN 'Pit Stops'
            WHEN o."lap" = 1 AND ABS(r_grid1."grid" - r_grid2."grid") <= 2 THEN 'Start-related overtakes'
            ELSE 'Standard on-track passes'
        END AS "category"
    FROM
        overtakes o
    LEFT JOIN
        "F1"."F1"."RETIREMENTS" r_ret
    ON
        o."race_id" = r_ret."race_id"
        AND o."overtaken_driver_id" = r_ret."driver_id"
        AND r_ret."lap" = o."lap"
    LEFT JOIN
        "F1"."F1"."PIT_STOPS" ps
    ON
        o."race_id" = ps."race_id"
        AND o."overtaken_driver_id" = ps."driver_id"
        AND ps."lap" IN (o."lap", o."lap" - 1)
    LEFT JOIN
        "F1"."F1"."RESULTS" r_grid1
    ON
        o."race_id" = r_grid1."race_id"
        AND o."overtaking_driver_id" = r_grid1."driver_id"
    LEFT JOIN
        "F1"."F1"."RESULTS" r_grid2
    ON
        o."race_id" = r_grid2."race_id"
        AND o."overtaken_driver_id" = r_grid2."driver_id"
)
SELECT
    "category" AS "Category",
    COUNT(DISTINCT o."overtaking_driver_id" || '-' || o."overtaken_driver_id" || '-' || o."lap") AS "Number"
FROM
    overtakes_classified o
GROUP BY
    "category"
ORDER BY
    CASE
        WHEN "category" = 'Retirements' THEN 1
        WHEN "category" = 'Pit Stops' THEN 2
        WHEN "category" = 'Start-related overtakes' THEN 3
        WHEN "category" = 'Standard on-track passes' THEN 4
    END;
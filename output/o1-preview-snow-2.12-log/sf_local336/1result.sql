WITH positions AS (
    SELECT "race_id", "driver_id", 0 AS "lap", "grid" AS "position"
    FROM "F1"."F1"."RESULTS"
    UNION ALL
    SELECT "race_id", "driver_id", "lap", "position"
    FROM "F1"."F1"."LAP_TIMES"
    WHERE "lap" BETWEEN 1 AND 5
),
positions_prev AS (
    SELECT "race_id", "driver_id", "lap" + 1 AS "lap", "position" AS "prev_position"
    FROM positions
    WHERE "lap" BETWEEN 0 AND 4
),
positions_with_prev AS (
    SELECT
        c."race_id",
        c."driver_id",
        c."lap",
        c."position",
        p."prev_position"
    FROM positions c
    LEFT JOIN positions_prev p ON c."race_id" = p."race_id" AND c."driver_id" = p."driver_id" AND c."lap" = p."lap"
    WHERE c."lap" BETWEEN 1 AND 5
),
overtakes AS (
    SELECT
        c1."race_id",
        c1."lap",
        c1."driver_id" AS "overtaker_id",
        c2."driver_id" AS "overtaken_id",
        c1."prev_position" AS "overtaker_prev_position",
        c1."position" AS "overtaker_position",
        c2."prev_position" AS "overtaken_prev_position",
        c2."position" AS "overtaken_position"
    FROM positions_with_prev c1
    JOIN positions_with_prev c2 ON c1."race_id" = c2."race_id" AND c1."lap" = c2."lap" AND c1."driver_id" != c2."driver_id"
    WHERE
        c1."prev_position" > c2."prev_position" -- c1 was behind c2 at prev lap
        AND c1."position" < c2."position" -- c1 is ahead of c2 at current lap
),
overtake_classification AS (
    SELECT
        o.*,
        CASE
            WHEN r."driver_id" IS NOT NULL THEN 'Retirements'
            WHEN p."driver_id" IS NOT NULL THEN 'Pit Stops'
            WHEN o."lap" = 1 AND ABS(grido."grid" - gridt."grid") <= 2 THEN 'Start-related overtakes'
            ELSE 'Standard on-track passes'
        END AS "Category"
    FROM overtakes o
    LEFT JOIN "F1"."F1"."RETIREMENTS" r ON o."race_id" = r."race_id" AND o."overtaken_id" = r."driver_id" AND r."lap" = o."lap"
    LEFT JOIN "F1"."F1"."PIT_STOPS" p ON o."race_id" = p."race_id" AND o."overtaken_id" = p."driver_id" AND p."lap" = o."lap"
    LEFT JOIN "F1"."F1"."RESULTS" grido ON o."race_id" = grido."race_id" AND o."overtaker_id" = grido."driver_id"
    LEFT JOIN "F1"."F1"."RESULTS" gridt ON o."race_id" = gridt."race_id" AND o."overtaken_id" = gridt."driver_id"
)
SELECT "Category", COUNT(*) AS "Number"
FROM overtake_classification
GROUP BY "Category"
ORDER BY
  CASE "Category"
    WHEN 'Retirements' THEN 1
    WHEN 'Pit Stops' THEN 2
    WHEN 'Start-related overtakes' THEN 3
    WHEN 'Standard on-track passes' THEN 4
    ELSE 5
  END;
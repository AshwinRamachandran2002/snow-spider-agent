WITH lap_positions AS (
    SELECT
        lp."race_id",
        lp."driver_id",
        lp."lap",
        lp."position"
    FROM
        "F1"."F1"."LAP_POSITIONS" lp
    WHERE
        lp."lap" BETWEEN 1 AND 5
),
position_changes AS (
    SELECT
        lp1."race_id",
        lp1."driver_id",
        lp1."lap",
        lp1."position" AS "position_current",
        lp2."position" AS "position_next",
        lp1."position" - lp2."position" AS "position_change"
    FROM
        lap_positions lp1
    JOIN
        lap_positions lp2 ON lp1."race_id" = lp2."race_id" AND lp1."driver_id" = lp2."driver_id" AND lp2."lap" = lp1."lap" + 1
    WHERE
        lp1."position" > lp2."position"
),
overtaken_drivers AS (
    SELECT
        pc."race_id",
        pc."driver_id" AS "overtaking_driver_id",
        pc."lap",
        lp."driver_id" AS "overtaken_driver_id"
    FROM
        position_changes pc
    JOIN
        lap_positions lp ON pc."race_id" = lp."race_id" AND lp."lap" = pc."lap" AND lp."position" BETWEEN pc."position_next" AND pc."position_current" - 1
),
retirement_overtakes AS (
    SELECT DISTINCT
        od."race_id",
        od."overtaking_driver_id",
        od."overtaken_driver_id"
    FROM
        overtaken_drivers od
    JOIN
        "F1"."F1"."RETIREMENTS" r ON od."race_id" = r."race_id" AND od."overtaken_driver_id" = r."driver_id" AND r."lap" = od."lap"
),
pitstop_overtakes AS (
    SELECT DISTINCT
        od."race_id",
        od."overtaking_driver_id",
        od."overtaken_driver_id"
    FROM
        overtaken_drivers od
    JOIN
        "F1"."F1"."PIT_STOPS" ps ON od."race_id" = ps."race_id" AND od."overtaken_driver_id" = ps."driver_id" AND ps."lap" = od."lap"
),
start_overtakes AS (
    SELECT DISTINCT
        od."race_id",
        od."overtaking_driver_id",
        od."overtaken_driver_id"
    FROM
        overtaken_drivers od
    JOIN
        "F1"."F1"."QUALIFYING" q1 ON od."race_id" = q1."race_id" AND od."overtaking_driver_id" = q1."driver_id"
    JOIN
        "F1"."F1"."QUALIFYING" q2 ON od."race_id" = q2."race_id" AND od."overtaken_driver_id" = q2."driver_id"
    WHERE
        od."lap" = 1 AND ABS(q1."position" - q2."position") <= 2
),
standard_overtakes AS (
    SELECT DISTINCT
        od."race_id",
        od."overtaking_driver_id",
        od."overtaken_driver_id"
    FROM
        overtaken_drivers od
    LEFT JOIN retirement_overtakes ro ON od."race_id" = ro."race_id" AND od."overtaking_driver_id" = ro."overtaking_driver_id" AND od."overtaken_driver_id" = ro."overtaken_driver_id"
    LEFT JOIN pitstop_overtakes po ON od."race_id" = po."race_id" AND od."overtaking_driver_id" = po."overtaking_driver_id" AND od."overtaken_driver_id" = po."overtaken_driver_id"
    LEFT JOIN start_overtakes so ON od."race_id" = so."race_id" AND od."overtaking_driver_id" = so."overtaking_driver_id" AND od."overtaken_driver_id" = so."overtaken_driver_id"
    WHERE
        ro."overtaking_driver_id" IS NULL AND po."overtaking_driver_id" IS NULL AND so."overtaking_driver_id" IS NULL
)
SELECT 'Retirements' AS "Category", COUNT(*) AS "Number" FROM retirement_overtakes
UNION ALL
SELECT 'Pit Stops' AS "Category", COUNT(*) AS "Number" FROM pitstop_overtakes
UNION ALL
SELECT 'Start-related overtakes' AS "Category", COUNT(*) AS "Number" FROM start_overtakes
UNION ALL
SELECT 'Standard on-track passes' AS "Category", COUNT(*) AS "Number" FROM standard_overtakes
ORDER BY
    CASE "Category"
        WHEN 'Retirements' THEN 1
        WHEN 'Pit Stops' THEN 2
        WHEN 'Start-related overtakes' THEN 3
        WHEN 'Standard on-track passes' THEN 4
    END;
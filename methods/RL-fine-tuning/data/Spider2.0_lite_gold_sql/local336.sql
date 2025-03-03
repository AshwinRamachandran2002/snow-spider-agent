WITH overtakes_lap1 AS (
    SELECT
        lp."race_id",
        lp."driver_id",
        1 AS "lap",
        lp."position" AS "current_position",
        r."grid" AS "previous_position",
        'Start-Related Overtakes' AS "overtake_category"
    FROM
        "lap_positions" lp
    JOIN
        "results" r
    ON
        lp."race_id" = r."race_id" AND lp."driver_id" = r."driver_id"
    WHERE
        lp."lap" = 1
        AND lp."position" IS NOT NULL
        AND r."grid" IS NOT NULL
        AND lp."position" < r."grid"
),
overtakes_lap2_5 AS (
    SELECT
        lp_current."race_id",
        lp_current."driver_id",
        lp_current."lap",
        lp_current."position" AS "current_position",
        lp_previous."position" AS "previous_position",
        NULL AS "overtake_category"
    FROM
        "lap_positions" lp_current
    JOIN
        "lap_positions" lp_previous
    ON
        lp_current."race_id" = lp_previous."race_id"
        AND lp_current."driver_id" = lp_previous."driver_id"
        AND lp_current."lap" = lp_previous."lap" + 1
    WHERE
        lp_current."lap" BETWEEN 2 AND 5
        AND lp_current."position" IS NOT NULL
        AND lp_previous."position" IS NOT NULL
        AND lp_current."position" < lp_previous."position"
),
all_overtakes AS (
    SELECT * FROM overtakes_lap1
    UNION ALL
    SELECT * FROM overtakes_lap2_5
)
SELECT
    "Category",
    COUNT(*) AS "Number of Overtakes"
FROM (
    SELECT
        o.*,
        CASE
            WHEN o."overtake_category" = 'Start-Related Overtakes' THEN 'Start-Related Overtakes'
            WHEN EXISTS (
                SELECT 1 FROM "retirements" AS r
                WHERE r."race_id" = o."race_id"
                AND r."lap" = o."lap"
                AND r."driver_id" IN (
                    SELECT lp_prev."driver_id"
                    FROM "lap_positions" lp_prev
                    WHERE lp_prev."race_id" = o."race_id"
                    AND lp_prev."lap" = o."lap" - 1
                    AND lp_prev."position" BETWEEN o."current_position" AND o."previous_position" - 1
                )
            ) THEN 'Retirements'
            WHEN EXISTS (
                SELECT 1 FROM "pit_stops" AS ps
                WHERE ps."race_id" = o."race_id"
                AND ps."lap" = o."lap"
                AND ps."driver_id" IN (
                    SELECT lp_prev."driver_id"
                    FROM "lap_positions" lp_prev
                    WHERE lp_prev."race_id" = o."race_id"
                    AND lp_prev."lap" = o."lap" - 1
                    AND lp_prev."position" BETWEEN o."current_position" AND o."previous_position" - 1
                )
            ) THEN 'Pit Stops'
            ELSE 'Standard On-Track Passes'
        END AS "Category"
    FROM
        all_overtakes o
) categorized_overtakes
GROUP BY
    "Category"
ORDER BY
    CASE
        WHEN "Category" = 'Retirements' THEN 1
        WHEN "Category" = 'Pit Stops' THEN 2
        WHEN "Category" = 'Start-Related Overtakes' THEN 3
        WHEN "Category" = 'Standard On-Track Passes' THEN 4
    END;
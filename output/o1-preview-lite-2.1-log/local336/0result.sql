WITH overtakes AS (
    SELECT
        lp1."race_id",
        lp1."driver_id",
        lp1."lap",
        lp1."position" AS "current_position",
        lp2."position" AS "previous_position"
    FROM "lap_positions" lp1
    JOIN "lap_positions" lp2
        ON lp1."driver_id" = lp2."driver_id"
        AND lp1."race_id" = lp2."race_id"
        AND lp1."lap" = lp2."lap" + 1
    WHERE lp1."lap" BETWEEN 2 AND 5
      AND lp1."position" < lp2."position"
),
overtake_types AS (
    SELECT
        o.*,
        CASE
            WHEN EXISTS (
                SELECT 1 FROM "pit_stops" ps
                WHERE ps."race_id" = o."race_id"
                  AND ps."lap" = o."lap"
                  AND ps."driver_id" IN (
                      SELECT lp."driver_id"
                      FROM "lap_positions" lp
                      WHERE lp."race_id" = o."race_id"
                        AND lp."lap" = o."lap"
                        AND lp."position" = o."current_position" + 1
                  )
            ) THEN 'Pit_Stop'
            WHEN EXISTS (
                SELECT 1 FROM "retirements" r
                WHERE r."race_id" = o."race_id"
                  AND r."lap" = o."lap"
                  AND r."driver_id" IN (
                      SELECT lp."driver_id"
                      FROM "lap_positions" lp
                      WHERE lp."race_id" = o."race_id"
                        AND lp."lap" = o."lap"
                        AND lp."position" = o."current_position" + 1
                  )
            ) THEN 'Retirement'
            ELSE 'Normal'
        END AS "Overtake_Type"
    FROM overtakes o
)
SELECT "Overtake_Type", COUNT(*) AS "Number_of_Overtakes"
FROM overtake_types
GROUP BY "Overtake_Type";
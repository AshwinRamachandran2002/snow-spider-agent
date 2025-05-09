SELECT
    COUNT(*) AS "Total_Overtakes"
FROM (
    SELECT
        lp1."driver_id",
        lp1."lap",
        lp1."position" AS "position_start",
        lp2."position" AS "position_end"
    FROM
        "lap_positions" lp1
    JOIN
        "lap_positions" lp2 ON lp1."driver_id" = lp2."driver_id"
        AND lp1."race_id" = lp2."race_id"
        AND lp2."lap" = lp1."lap" + 1
    WHERE
        lp1."race_id" = 1
        AND lp1."lap" BETWEEN 1 AND 4
        AND lp1."position" > lp2."position"
) AS overtakes;
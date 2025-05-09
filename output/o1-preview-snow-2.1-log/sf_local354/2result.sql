SELECT DISTINCT
    d."full_name" AS "Driver_Name"
FROM
    "F1"."F1"."DRIVERS" d
    INNER JOIN (
        SELECT
            d1."driver_id",
            d1."year",
            d1."constructor_id"
        FROM
            "F1"."F1"."DRIVES" d1
            JOIN "F1"."F1"."DRIVES" d2
                ON d1."driver_id" = d2."driver_id"
                AND d1."year" = d2."year"
        WHERE
            d1."is_first_drive_of_season" = 1
            AND d2."is_final_drive_of_season" = 1
            AND d1."constructor_id" = d2."constructor_id"
            AND d1."year" BETWEEN 1950 AND 1959
    ) drv
        ON drv."driver_id" = d."driver_id"
    INNER JOIN (
        SELECT
            r."driver_id",
            ra."year",
            COUNT(DISTINCT ra."round") AS "race_count"
        FROM
            "F1"."F1"."RESULTS" r
            JOIN "F1"."F1"."RACES" ra
                ON r."race_id" = ra."race_id"
        WHERE
            ra."year" BETWEEN 1950 AND 1959
        GROUP BY
            r."driver_id",
            ra."year"
        HAVING
            COUNT(DISTINCT ra."round") >= 2
    ) res
        ON drv."driver_id" = res."driver_id"
        AND drv."year" = res."year"
ORDER BY
    d."full_name";
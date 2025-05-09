SELECT DISTINCT DR."forename" || ' ' || DR."surname" AS "Driver_Name"
FROM 
    (
        SELECT 
            D."driver_id",
            D."year",
            D1."constructor_id" AS "constructor_id"
        FROM F1.F1."DRIVES" D
        JOIN F1.F1."DRIVES" D1 
            ON D."driver_id" = D1."driver_id" 
            AND D."year" = D1."year" 
            AND D1."is_first_drive_of_season" = 1
        JOIN F1.F1."DRIVES" D2 
            ON D."driver_id" = D2."driver_id" 
            AND D."year" = D2."year" 
            AND D2."is_final_drive_of_season" = 1
        WHERE D."year" BETWEEN 1950 AND 1959
            AND D1."constructor_id" = D2."constructor_id"
        GROUP BY D."driver_id", D."year", D1."constructor_id"
    ) AS FLC
JOIN
    (
        SELECT 
            R."driver_id",
            RA."year"
        FROM F1.F1."RESULTS" R
        JOIN F1.F1."RACES" RA ON R."race_id" = RA."race_id"
        WHERE RA."year" BETWEEN 1950 AND 1959
        GROUP BY R."driver_id", RA."year"
        HAVING COUNT(DISTINCT RA."round") >= 2
    ) AS DWR
    ON FLC."driver_id" = DWR."driver_id" AND FLC."year" = DWR."year"
JOIN F1.F1."DRIVERS" DR ON FLC."driver_id" = DR."driver_id"
ORDER BY "Driver_Name";
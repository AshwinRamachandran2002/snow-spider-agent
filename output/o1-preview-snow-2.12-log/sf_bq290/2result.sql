SELECT
    TO_DATE(CONCAT(us_data."year", '-', us_data."mo", '-', us_data."da"), 'YYYY-MM-DD') AS "Date",
    ROUND(us_data."US_max_temp" - uk_data."UK_max_temp", 4) AS "Max_Temperature_Difference",
    ROUND(us_data."US_min_temp" - uk_data."UK_min_temp", 4) AS "Min_Temperature_Difference",
    ROUND(us_data."US_avg_temp" - uk_data."UK_avg_temp", 4) AS "Avg_Temperature_Difference"
FROM
    (
        SELECT
            gsod."year", gsod."mo", gsod."da",
            MAX(gsod."max") AS "US_max_temp",
            MIN(gsod."min") AS "US_min_temp",
            AVG(gsod."temp") AS "US_avg_temp"
        FROM
            "NOAA_DATA"."NOAA_GSOD"."GSOD2023" AS gsod
        INNER JOIN
            "NOAA_DATA"."NOAA_GSOD"."STATIONS" AS stations
            ON gsod."stn" = stations."usaf" AND gsod."wban" = stations."wban"
        WHERE
            gsod."year" = '2023' AND gsod."mo" = '10'
            AND stations."country" = 'US'
            AND gsod."temp" IS NOT NULL
            AND gsod."max" IS NOT NULL AND gsod."max" <> 9999.9
            AND gsod."min" IS NOT NULL AND gsod."min" <> 9999.9
        GROUP BY
            gsod."year", gsod."mo", gsod."da"
    ) AS us_data
INNER JOIN
    (
        SELECT
            gsod."year", gsod."mo", gsod."da",
            MAX(gsod."max") AS "UK_max_temp",
            MIN(gsod."min" ) AS "UK_min_temp",
            AVG(gsod."temp") AS "UK_avg_temp"
        FROM
            "NOAA_DATA"."NOAA_GSOD"."GSOD2023" AS gsod
        INNER JOIN
            "NOAA_DATA"."NOAA_GSOD"."STATIONS" AS stations
            ON gsod."stn" = stations."usaf" AND gsod."wban" = stations."wban"
        WHERE
            gsod."year" = '2023' AND gsod."mo" = '10'
            AND stations."country" = 'UK'
            AND gsod."temp" IS NOT NULL
            AND gsod."max" IS NOT NULL AND gsod."max" <> 9999.9
            AND gsod."min" IS NOT NULL AND gsod."min" <> 9999.9
        GROUP BY
            gsod."year", gsod."mo", gsod."da"
    ) AS uk_data
ON
    us_data."year" = uk_data."year" AND
    us_data."mo" = uk_data."mo" AND
    us_data."da" = uk_data."da"
ORDER BY
    us_data."year", us_data."mo", us_data."da";
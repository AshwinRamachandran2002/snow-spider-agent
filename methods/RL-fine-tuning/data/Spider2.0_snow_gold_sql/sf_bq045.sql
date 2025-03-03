SELECT
    s."usaf" AS "station_id",
    s."name" AS "station_name",
    rd23."rainy_days_2023" AS "number_of_rainy_days_2023",
    rd22."rainy_days_2022" AS "number_of_rainy_days_2022"
FROM
    NOAA_DATA.NOAA_GSOD.STATIONS s
    JOIN (
        SELECT
            g."stn",
            COUNT(*) AS "rainy_days_2023"
        FROM
            NOAA_DATA.NOAA_GSOD.GSOD2023 g
        WHERE
            g."prcp" > 0
            AND g."prcp" != 99.99
            AND g."stn" != '999999'
        GROUP BY
            g."stn"
    ) rd23 ON s."usaf" = rd23."stn"
    JOIN (
        SELECT
            g."stn",
            COUNT(*) AS "rainy_days_2022"
        FROM
            NOAA_DATA.NOAA_GSOD.GSOD2022 g
        WHERE
            g."prcp" > 0
            AND g."prcp" != 99.99
            AND g."stn" != '999999'
        GROUP BY
            g."stn"
    ) rd22 ON s."usaf" = rd22."stn"
WHERE
    s."state" = 'WA'
    AND s."usaf" != '999999'
    AND rd23."rainy_days_2023" > 150
    AND rd23."rainy_days_2023" < rd22."rainy_days_2022";
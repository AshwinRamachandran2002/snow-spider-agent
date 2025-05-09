SELECT
    ROUND(
        (
            (
                SELECT COUNT(DISTINCT "stn")
                FROM (
                    SELECT "stn", COUNT(*) AS "temp_days"
                    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2022"
                    WHERE "temp" IS NOT NULL AND "year" = '2022'
                    GROUP BY "stn"
                    HAVING COUNT(*) >= 329
                ) AS stations_with_90_percent
            )::FLOAT
            /
            (
                SELECT COUNT(DISTINCT "stn")
                FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2022"
                WHERE "year" = '2022'
            )
        ) * 100
        , 4
    ) AS "Percentage_of_Stations";
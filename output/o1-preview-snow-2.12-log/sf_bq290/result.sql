WITH daily_country_temps AS (
    SELECT
        DATE_FROM_PARTS(TO_NUMBER("GSOD"."year"), TO_NUMBER("GSOD"."mo"), TO_NUMBER("GSOD"."da")) AS "Date",
        "ST"."country" AS "Country",
        AVG("GSOD"."max") AS "Avg_Max_Temp",
        AVG("GSOD"."min") AS "Avg_Min_Temp",
        AVG("GSOD"."temp") AS "Avg_Temp"
    FROM
        "NOAA_DATA"."NOAA_GSOD"."GSOD2023" AS "GSOD"
    JOIN
        "NOAA_DATA"."NOAA_GSOD"."STATIONS" AS "ST"
        ON "GSOD"."stn" = "ST"."usaf" AND "GSOD"."wban" = "ST"."wban"
    WHERE
        "GSOD"."year" = '2023'
        AND "GSOD"."mo" = '10'
        AND "ST"."country" IN ('US', 'UK')
        AND "GSOD"."temp" IS NOT NULL
        AND "GSOD"."max" IS NOT NULL
        AND "GSOD"."min" IS NOT NULL
    GROUP BY
        DATE_FROM_PARTS(TO_NUMBER("GSOD"."year"), TO_NUMBER("GSOD"."mo"), TO_NUMBER("GSOD"."da")),
        "ST"."country"
)
SELECT
    d1."Date",
    ROUND(d1."Avg_Max_Temp" - d2."Avg_Max_Temp", 4) AS "Max_Temperature_Difference",
    ROUND(d1."Avg_Min_Temp" - d2."Avg_Min_Temp", 4) AS "Min_Temperature_Difference",
    ROUND(d1."Avg_Temp" - d2."Avg_Temp", 4) AS "Avg_Temperature_Difference"
FROM
    daily_country_temps d1
JOIN
    daily_country_temps d2
    ON d1."Date" = d2."Date"
WHERE
    d1."Country" = 'US'
    AND d2."Country" = 'UK'
ORDER BY
    d1."Date";
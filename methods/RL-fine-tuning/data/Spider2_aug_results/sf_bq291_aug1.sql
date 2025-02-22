-- Task: Provide the maximum, minimum, and average temperatures for each forecast date for July 2019 within a 5 km radius of latitude 26.75 and longitude 51.5. The data should correspond to forecasts created in July 2019 for the following day.

SELECT
    TO_TIMESTAMP_NTZ(TO_NUMBER("TRI"."creation_time") / 1000000) AS "creation_time",
    CAST(DATEADD(hour, 1, TO_TIMESTAMP_NTZ(TO_NUMBER("forecast".value:"time") / 1000000)) AS DATE) AS "local_forecast_date",
    MAX("forecast".value:"temperature_2m_above_ground") AS "max_temp",
    MIN("forecast".value:"temperature_2m_above_ground") AS "min_temp",
    AVG("forecast".value:"temperature_2m_above_ground") AS "avg_temp"
FROM
    "NOAA_GLOBAL_FORECAST_SYSTEM"."NOAA_GLOBAL_FORECAST_SYSTEM"."NOAA_GFS0P25" AS "TRI"
CROSS JOIN LATERAL FLATTEN(input => "TRI"."forecast") AS "forecast"
WHERE
    TO_TIMESTAMP_NTZ(TO_NUMBER("TRI"."creation_time") / 1000000) BETWEEN '2019-07-01' AND '2019-07-31'  
    AND ST_DWITHIN(
        ST_GEOGFROMWKB("TRI"."geography"),
        ST_POINT(26.75, 51.5),
        5000
    )
    AND CAST(TO_TIMESTAMP_NTZ(TO_NUMBER("forecast".value:"time") / 1000000) AS DATE) = DATEADD(day, 1, CAST(TO_TIMESTAMP_NTZ(TO_NUMBER("TRI"."creation_time") / 1000000) AS DATE))
GROUP BY
    "TRI"."creation_time",
    "local_forecast_date"
ORDER BY
    "creation_time",
    "local_forecast_date";
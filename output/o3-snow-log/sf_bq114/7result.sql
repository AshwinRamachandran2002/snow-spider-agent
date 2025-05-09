WITH epa_1990 AS (
    SELECT
        ROUND("latitude", 2)  AS lat2 ,
        ROUND("longitude", 2) AS lon2 ,
        AVG("arithmetic_mean") AS pm25_1990
    FROM OPENAQ.EPA_HISTORICAL_AIR_QUALITY.PM25_NONFRM_DAILY_SUMMARY
    WHERE YEAR("date_local") = 1990
      AND "units_of_measure" = 'Micrograms/cubic meter (LC)'
      AND "parameter_name"   = 'Acceptable PM2.5 AQI & Speciation Mass'
    GROUP BY lat2, lon2
),
openaq_2020 AS (
    SELECT
        ROUND("latitude", 2)  AS lat2 ,
        ROUND("longitude", 2) AS lon2 ,
        AVG("value")          AS pm25_2020 ,
        MAX("city")           AS city
    FROM OPENAQ.OPENAQ.GLOBAL_AIR_QUALITY
    WHERE "pollutant" = 'pm25'
      AND YEAR(TO_TIMESTAMP_NTZ("timestamp" / 1000000)) = 2020
    GROUP BY lat2, lon2
)
SELECT
    o.city                                AS "city",
    e.lat2                                AS "latitude_rounded",
    e.lon2                                AS "longitude_rounded",
    e.pm25_1990                           AS "pm25_1990",
    o.pm25_2020                           AS "pm25_2020",
    ABS(o.pm25_2020 - e.pm25_1990)        AS "difference"
FROM epa_1990 e
JOIN openaq_2020 o
  ON e.lat2 = o.lat2
 AND e.lon2 = o.lon2
ORDER BY "difference" DESC NULLS LAST
LIMIT 3;
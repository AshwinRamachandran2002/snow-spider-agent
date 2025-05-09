WITH epa_1990 AS (
    SELECT
        ROUND("latitude", 2)  AS lat2,
        ROUND("longitude", 2) AS lon2,
        AVG("arithmetic_mean") AS epa_pm25,
        MIN("city_name")       AS epa_city
    FROM OPENAQ.EPA_HISTORICAL_AIR_QUALITY.PM25_NONFRM_DAILY_SUMMARY
    WHERE "units_of_measure" = 'Micrograms/cubic meter (LC)'
      AND "parameter_name"   = 'Acceptable PM2.5 AQI & Speciation Mass'
      AND YEAR("date_local") = 1990
    GROUP BY
        ROUND("latitude", 2),
        ROUND("longitude", 2)
),  
openaq_2020 AS (
    SELECT
        ROUND("latitude", 2)  AS lat2,
        ROUND("longitude", 2) AS lon2,
        AVG("value")           AS openaq_pm25,
        MIN("city")            AS openaq_city
    FROM OPENAQ.OPENAQ.GLOBAL_AIR_QUALITY
    WHERE "pollutant" = 'pm25'
      AND YEAR(TO_TIMESTAMP("timestamp" / 1000000)) = 2020
    GROUP BY
        ROUND("latitude", 2),
        ROUND("longitude", 2)
)
SELECT
    COALESCE(e.epa_city, o.openaq_city) AS "city",
    ABS(e.epa_pm25 - o.openaq_pm25)     AS "difference"
FROM epa_1990 e
JOIN openaq_2020 o
  ON e.lat2 = o.lat2
 AND e.lon2 = o.lon2
ORDER BY "difference" DESC NULLS LAST
LIMIT 3;
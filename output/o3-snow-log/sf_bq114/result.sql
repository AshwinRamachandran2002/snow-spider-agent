WITH epa_1990 AS (
    SELECT
        ROUND("latitude", 2)  AS lat2,
        ROUND("longitude", 2) AS lon2,
        AVG("arithmetic_mean") AS epa_pm25_1990,
        MAX("city_name")       AS city_1990
    FROM OPENAQ.EPA_HISTORICAL_AIR_QUALITY.PM25_NONFRM_DAILY_SUMMARY
    WHERE "parameter_name"   = 'Acceptable PM2.5 AQI & Speciation Mass'
      AND "units_of_measure" = 'Micrograms/cubic meter (LC)'
      AND YEAR("date_local") = 1990
    GROUP BY lat2, lon2
), openaq_2020 AS (
    SELECT
        ROUND("latitude", 2)  AS lat2,
        ROUND("longitude", 2) AS lon2,
        AVG("value")           AS openaq_pm25_2020,
        MAX("city")            AS city_2020
    FROM OPENAQ.OPENAQ.GLOBAL_AIR_QUALITY
    WHERE "pollutant" = 'pm25'
      AND YEAR( TO_TIMESTAMP_NTZ("timestamp" / 1000000) ) = 2020
    GROUP BY lat2, lon2
)
SELECT
    COALESCE(o.city_2020, e.city_1990)    AS "city",
    ABS(o.openaq_pm25_2020 - e.epa_pm25_1990) AS "pm25_difference"
FROM openaq_2020 o
JOIN epa_1990   e
  ON o.lat2 = e.lat2
 AND o.lon2 = e.lon2
ORDER BY "pm25_difference" DESC NULLS LAST
LIMIT 3;
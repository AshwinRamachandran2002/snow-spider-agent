WITH epa_1990 AS (
    SELECT
        ROUND("latitude", 2)  AS lat2,
        ROUND("longitude", 2) AS lon2,
        MAX("city_name")      AS city_1990,
        AVG("arithmetic_mean") AS pm25_1990
    FROM OPENAQ.EPA_HISTORICAL_AIR_QUALITY.PM25_NONFRM_DAILY_SUMMARY
    WHERE "parameter_name"  = 'Acceptable PM2.5 AQI & Speciation Mass'
      AND "units_of_measure" = 'Micrograms/cubic meter (LC)'
      AND EXTRACT(YEAR FROM "date_local") = 1990
    GROUP BY lat2, lon2
),
openaq_2020 AS (
    SELECT
        ROUND("latitude", 2)  AS lat2,
        ROUND("longitude", 2) AS lon2,
        MAX("city")           AS city_2020,
        AVG("value")          AS pm25_2020
    FROM OPENAQ.OPENAQ.GLOBAL_AIR_QUALITY
    WHERE "pollutant" = 'pm25'
      AND EXTRACT(YEAR FROM TO_TIMESTAMP("timestamp" / 1e6)) = 2020
    GROUP BY lat2, lon2
),
joined AS (
    SELECT
        COALESCE(o.city_2020, e.city_1990) AS city,
        e.pm25_1990,
        o.pm25_2020,
        ABS(e.pm25_1990 - o.pm25_2020)     AS diff
    FROM epa_1990 e
    JOIN openaq_2020 o
      ON e.lat2 = o.lat2
     AND e.lon2 = o.lon2
)
SELECT
    city,
    diff
FROM joined
ORDER BY diff DESC NULLS LAST
LIMIT 3;
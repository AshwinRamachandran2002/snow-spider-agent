WITH epa_1990 AS (   -- 1990 EPA PM2.5 values
    SELECT
        ROUND("latitude", 2)  AS lat2,
        ROUND("longitude", 2) AS lon2,
        AVG("arithmetic_mean") AS epa_pm25_1990
    FROM OPENAQ.EPA_HISTORICAL_AIR_QUALITY.PM25_NONFRM_DAILY_SUMMARY
    WHERE "parameter_name"   = 'Acceptable PM2.5 AQI & Speciation Mass'
      AND "units_of_measure" = 'Micrograms/cubic meter (LC)'
      AND EXTRACT(YEAR FROM "date_local") = 1990
    GROUP BY 1, 2
),
openaq_2020 AS (      -- 2020 OpenAQ PM2.5 values for the same coords
    SELECT
        ROUND(g."latitude", 2)  AS lat2,
        ROUND(g."longitude", 2) AS lon2,
        AVG(g."value")          AS openaq_pm25_2020,
        MAX(g."city")           AS city
    FROM OPENAQ.OPENAQ.GLOBAL_AIR_QUALITY g
    JOIN epa_1990 e
      ON ROUND(g."latitude", 2)  = e.lat2
     AND ROUND(g."longitude", 2) = e.lon2
    WHERE g."pollutant" = 'pm25'
      AND g."timestamp" BETWEEN 1577836800000000  -- 2020-01-01 (µs)
                           AND 1609459199999999   -- 2020-12-31 23:59:59 (µs)
    GROUP BY 1, 2
)
SELECT
    o.city,
    ABS(e.epa_pm25_1990 - o.openaq_pm25_2020) AS pm25_difference
FROM epa_1990 e
JOIN openaq_2020 o
  ON e.lat2 = o.lat2
 AND e.lon2 = o.lon2
ORDER BY pm25_difference DESC NULLS LAST
LIMIT 3;
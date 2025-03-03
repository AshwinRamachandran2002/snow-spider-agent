WITH epa_data AS (
    SELECT
        ROUND("latitude", 2) AS lat,
        ROUND("longitude", 2) AS lon,
        AVG("arithmetic_mean") AS avg_pm25_1990,
        MAX("city_name") AS city
    FROM "OPENAQ"."EPA_HISTORICAL_AIR_QUALITY"."AIR_QUALITY_ANNUAL_SUMMARY"
    WHERE "year" = 1990
      AND "parameter_name" = 'Acceptable PM2.5 AQI & Speciation Mass'
      AND "units_of_measure" = 'Micrograms/cubic meter (LC)'
    GROUP BY lat, lon
),
openaq_data AS (
    SELECT
        ROUND("latitude", 2) AS lat,
        ROUND("longitude", 2) AS lon,
        AVG("value") AS avg_pm25_2020,
        MAX("city") AS city
    FROM "OPENAQ"."OPENAQ"."GLOBAL_AIR_QUALITY"
    WHERE "pollutant" = 'pm25'
      AND EXTRACT(YEAR FROM TO_TIMESTAMP("timestamp" / 1000000)) = 2020
    GROUP BY lat, lon
),
combined_data AS (
    SELECT
        epa.lat,
        epa.lon,
        COALESCE(openaq.city, epa.city) AS city,
        epa.avg_pm25_1990,
        openaq.avg_pm25_2020,
        (openaq.avg_pm25_2020 - epa.avg_pm25_1990) AS difference
    FROM epa_data epa
    INNER JOIN openaq_data openaq
      ON epa.lat = openaq.lat AND epa.lon = openaq.lon
)
SELECT
    city,
    ROUND(difference, 4) AS difference
FROM combined_data
ORDER BY ABS(difference) DESC NULLS LAST
LIMIT 3;
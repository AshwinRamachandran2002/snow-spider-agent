WITH epa_1990 AS (   -- average 1990 PM2.5 for each EPA location (rounded lat/lon)
    SELECT
        ROUND("latitude", 2)  AS lat_round ,
        ROUND("longitude", 2) AS lon_round ,
        AVG("arithmetic_mean") AS pm25_1990 ,
        MIN("city_name")       AS city        -- pick one city name for the site
    FROM OPENAQ.EPA_HISTORICAL_AIR_QUALITY.PM25_NONFRM_DAILY_SUMMARY
    WHERE "parameter_name"   = 'Acceptable PM2.5 AQI & Speciation Mass'
      AND "units_of_measure" = 'Micrograms/cubic meter (LC)'
      AND YEAR("date_local") = 1990
    GROUP BY
        lat_round ,
        lon_round
),
openaq_2020 AS (      -- average 2020 PM2.5 for each OpenAQ location (rounded lat/lon)
    SELECT
        ROUND("latitude", 2)  AS lat_round ,
        ROUND("longitude", 2) AS lon_round ,
        AVG("value")           AS pm25_2020
    FROM OPENAQ.OPENAQ.GLOBAL_AIR_QUALITY
    WHERE "pollutant" = 'pm25'
      AND YEAR( TO_TIMESTAMP_LTZ("timestamp" / 1000000) ) = 2020
    GROUP BY
        lat_round ,
        lon_round
),
combined AS (         -- match the two datasets on rounded coordinates
    SELECT
        e.city ,
        e.pm25_1990 ,
        o.pm25_2020 ,
        ABS(o.pm25_2020 - e.pm25_1990) AS diff
    FROM epa_1990 e
    JOIN openaq_2020 o
      USING (lat_round , lon_round)
)
SELECT
    city ,
    pm25_1990 ,
    pm25_2020 ,
    diff
FROM combined
ORDER BY
    diff DESC NULLS LAST
LIMIT 3;
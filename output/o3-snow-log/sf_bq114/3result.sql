WITH epa_1990 AS (      -- 1990 EPA PM2.5 (daily summary)
    SELECT
        ROUND("latitude",  2) AS "lat2d",
        ROUND("longitude", 2) AS "lon2d",
        MAX("city_name")              AS "city",
        AVG("arithmetic_mean")        AS "epa_pm25"
    FROM OPENAQ.EPA_HISTORICAL_AIR_QUALITY.PM25_NONFRM_DAILY_SUMMARY
    WHERE "parameter_name"   = 'Acceptable PM2.5 AQI & Speciation Mass'
      AND "units_of_measure" = 'Micrograms/cubic meter (LC)'
      AND YEAR("date_local") = 1990
    GROUP BY
        ROUND("latitude",  2),
        ROUND("longitude", 2)
),
openaq_2020 AS (         -- 2020 OpenAQ PM2.5 (hourly / miscellaneous cadence)
    SELECT
        ROUND("latitude",  2) AS "lat2d",
        ROUND("longitude", 2) AS "lon2d",
        MAX("city")                   AS "city",
        AVG("value")                  AS "openaq_pm25"
    FROM OPENAQ.OPENAQ.GLOBAL_AIR_QUALITY
    WHERE "pollutant" = 'pm25'
      AND YEAR(TO_TIMESTAMP_LTZ("timestamp" / 1000000)) = 2020
    GROUP BY
        ROUND("latitude",  2),
        ROUND("longitude", 2)
),
joined AS (              -- match on rounded lat / lon
    SELECT
        COALESCE(e."city", o."city")     AS "city",
        e."epa_pm25",
        o."openaq_pm25",
        ABS(o."openaq_pm25" - e."epa_pm25") AS "difference"
    FROM epa_1990 e
    JOIN openaq_2020 o
      ON e."lat2d" = o."lat2d"
     AND e."lon2d" = o."lon2d"
)
SELECT
    "city",
    "difference"
FROM joined
ORDER BY "difference" DESC NULLS LAST
LIMIT 3;
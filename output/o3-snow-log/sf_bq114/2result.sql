WITH epa_1990 AS (   -- 1990 EPA PM2.5 (Non-FRM daily summary)
    SELECT
        ROUND("latitude", 2)  AS lat2,
        ROUND("longitude", 2) AS lon2,
        MAX("city_name")      AS city,
        AVG("arithmetic_mean")::FLOAT  AS epa_pm25
    FROM OPENAQ.EPA_HISTORICAL_AIR_QUALITY.PM25_NONFRM_DAILY_SUMMARY
    WHERE "units_of_measure" = 'Micrograms/cubic meter (LC)'
      AND "parameter_name"   = 'Acceptable PM2.5 AQI & Speciation Mass'
      AND YEAR("date_local") = 1990
    GROUP BY lat2, lon2
),
openaq_2020 AS (      -- 2020 OpenAQ PM2.5
    SELECT
        ROUND("latitude", 2)  AS lat2,
        ROUND("longitude", 2) AS lon2,
        MAX("city")           AS city,
        AVG("value")::FLOAT   AS openaq_pm25
    FROM OPENAQ.OPENAQ.GLOBAL_AIR_QUALITY
    WHERE "pollutant" = 'pm25'
      AND YEAR( TO_TIMESTAMP("timestamp" / 1000000) ) = 2020   -- epoch µs → year
    GROUP BY lat2, lon2
),
diffs AS (            -- match on rounded lat/lon & compute absolute difference
    SELECT
        COALESCE(e.city, o.city)          AS city,
        e.lat2,
        e.lon2,
        e.epa_pm25,
        o.openaq_pm25,
        ABS(e.epa_pm25 - o.openaq_pm25)   AS diff_pm25
    FROM epa_1990 e
    JOIN openaq_2020 o
      ON e.lat2 = o.lat2
     AND e.lon2 = o.lon2
    WHERE e.epa_pm25 IS NOT NULL
      AND o.openaq_pm25 IS NOT NULL
)
SELECT
    city,
    diff_pm25      AS pm25_difference,
    epa_pm25       AS epa_1990_pm25,
    openaq_pm25    AS openaq_2020_pm25
FROM diffs
ORDER BY diff_pm25 DESC NULLS LAST
LIMIT 3;
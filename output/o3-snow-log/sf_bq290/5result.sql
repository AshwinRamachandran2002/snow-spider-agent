WITH gsod_2023_oct AS (
    SELECT
        TO_DATE(g."year" || '-' || LPAD(g."mo", 2, '0') || '-' || LPAD(g."da", 2, '0')) AS "date",
        s."country",
        g."max",
        g."min",
        g."temp"
    FROM NOAA_DATA.NOAA_GSOD.GSOD2023 g
    JOIN NOAA_DATA.NOAA_GSOD.STATIONS s
      ON g."stn"  = s."usaf"
     AND g."wban" = s."wban"
    WHERE g."year" = '2023'
      AND g."mo"   = '10'                        -- October
      AND s."country" IN ('US', 'UK', 'GB')      -- United States & United Kingdom
      AND g."max"  < 9000                        -- exclude missing / invalid values
      AND g."min"  < 9000
      AND g."temp" < 9000
),
country_day AS (
    SELECT
        "date",
        "country",
        MAX("max")  AS day_max,
        MIN("min")  AS day_min,
        AVG("temp") AS day_avg
    FROM gsod_2023_oct
    GROUP BY "date", "country"
)
SELECT
    us."date",
    ROUND(us.day_max - uk.day_max, 4) AS diff_max_temperature,
    ROUND(us.day_min - uk.day_min, 4) AS diff_min_temperature,
    ROUND(us.day_avg - uk.day_avg, 4) AS diff_avg_temperature
FROM (SELECT * FROM country_day WHERE "country" = 'US') us
JOIN (SELECT * FROM country_day WHERE "country" IN ('UK', 'GB')) uk
  ON us."date" = uk."date"
ORDER BY us."date";
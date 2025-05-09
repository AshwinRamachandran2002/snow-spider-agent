WITH valid_data AS (
    SELECT
        TO_DATE(g."year" || '-' || LPAD(g."mo", 2, '0') || '-' || LPAD(g."da", 2, '0'))           AS "obs_date",
        s."country"                                                                              AS "country",
        g."max"                                                                                  AS "max_temp",
        g."min"                                                                                  AS "min_temp",
        g."temp"                                                                                 AS "avg_temp"
    FROM NOAA_DATA.NOAA_GSOD.GSOD2023 g
    JOIN NOAA_DATA.NOAA_GSOD.STATIONS  s
         ON g."stn" = s."usaf"
        AND g."wban" = s."wban"
    WHERE g."year" = '2023'
      AND g."mo"   = '10'           -- October 2023
      -- remove obvious missing / invalid values
      AND g."max"  <> 999.9
      AND g."min"  <> 999.9
      AND g."temp" <> 9999.9
      -- only US and UK stations
      AND s."country" IN ('US','UK')
),
country_daily AS (
    SELECT
        "obs_date",
        "country",
        AVG("max_temp") AS "avg_max_temp",
        AVG("min_temp") AS "avg_min_temp",
        AVG("avg_temp") AS "avg_avg_temp"
    FROM valid_data
    GROUP BY "obs_date", "country"
),
pivoted AS (
    SELECT
        "obs_date",
        MAX(CASE WHEN "country" = 'US' THEN "avg_max_temp" END) AS "us_max",
        MAX(CASE WHEN "country" = 'UK' THEN "avg_max_temp" END) AS "uk_max",
        MAX(CASE WHEN "country" = 'US' THEN "avg_min_temp" END) AS "us_min",
        MAX(CASE WHEN "country" = 'UK' THEN "avg_min_temp" END) AS "uk_min",
        MAX(CASE WHEN "country" = 'US' THEN "avg_avg_temp" END) AS "us_avg",
        MAX(CASE WHEN "country" = 'UK' THEN "avg_avg_temp" END) AS "uk_avg"
    FROM country_daily
    GROUP BY "obs_date"
)
SELECT
    "obs_date",
    ("us_max" - "uk_max") AS "diff_max_temperature",
    ("us_min" - "uk_min") AS "diff_min_temperature",
    ("us_avg" - "uk_avg") AS "diff_avg_temperature"
FROM pivoted
WHERE "us_max" IS NOT NULL
  AND "uk_max" IS NOT NULL      -- ensures both countries present
ORDER BY "obs_date";
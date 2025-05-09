WITH valid_obs AS (   -- 1.  keep only good-quality October-2023 records for US & UK
    SELECT
        TO_DATE(CONCAT("year",'-',LPAD("mo",2,'0'),'-',LPAD("da",2,'0')))  AS "date",
        st."country",
        g."max",
        g."min",
        g."temp"
    FROM   NOAA_DATA.NOAA_GSOD."GSOD2023"  g
    JOIN   NOAA_DATA.NOAA_GSOD."STATIONS"  st
           ON g."stn"  = st."usaf"
          AND g."wban" = st."wban"
    WHERE  g."year" = '2023'
      AND  g."mo"   = '10'                -- October only
      AND  st."country" IN ('US','UK')    -- United States & United Kingdom
      AND  g."max"  < 9000                -- filter out 9999.9 missing values
      AND  g."min"  < 9000
      AND  g."temp" < 9000
),

country_daily AS (    -- 2. average by country for each day
    SELECT
        "date",
        "country",
        AVG("max")  AS avg_max,
        AVG("min")  AS avg_min,
        AVG("temp") AS avg_temp
    FROM   valid_obs
    GROUP  BY "date", "country"
),

pivoted AS (          -- 3. put US & UK averages on the same row
    SELECT
        "date",
        MAX(CASE WHEN "country" = 'US' THEN avg_max  END) AS us_max,
        MAX(CASE WHEN "country" = 'UK' THEN avg_max  END) AS uk_max,
        MAX(CASE WHEN "country" = 'US' THEN avg_min  END) AS us_min,
        MAX(CASE WHEN "country" = 'UK' THEN avg_min  END) AS uk_min,
        MAX(CASE WHEN "country" = 'US' THEN avg_temp END) AS us_avg,
        MAX(CASE WHEN "country" = 'UK' THEN avg_temp END) AS uk_avg
    FROM   country_daily
    GROUP  BY "date"
)

-- 4. calculate US-minus-UK differences
SELECT
    "date",
    us_max - uk_max  AS diff_max_temperature,
    us_min - uk_min  AS diff_min_temperature,
    us_avg - uk_avg  AS diff_avg_temperature
FROM   pivoted
ORDER  BY "date";
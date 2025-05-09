WITH daily_temps AS (
    SELECT
        TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0')) AS dt,
        "temp"
    FROM NOAA_GSOD.NOAA_GSOD.GSOD2009
    WHERE "stn" = '723758'
      AND "mo"  = '10'            -- October
      AND "temp" <> 9999.9        -- exclude missing values
)
SELECT TO_CHAR(dt, 'YYYY-MM-DD') AS "DATE"
FROM (
    SELECT dt, AVG("temp") AS avg_temp
    FROM daily_temps
    GROUP BY dt
)
ORDER BY avg_temp DESC NULLS LAST
LIMIT 3;
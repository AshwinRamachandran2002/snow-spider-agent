WITH candidate_stations AS (      -- stations with long-term records spanning 2019
    SELECT
        "usaf"   AS "stn",
        "wban",
        TO_DATE("begin", 'YYYYMMDD') AS "begin_date",
        TO_DATE("end"  , 'YYYYMMDD') AS "end_date"
    FROM NOAA_DATA.NOAA_GSOD.STATIONS
    WHERE TO_DATE("begin", 'YYYYMMDD') <= '2000-01-01'
      AND TO_DATE("end"  , 'YYYYMMDD') >= '2019-06-30'
),
valid_2019 AS (                   -- 2019 daily rows with non-missing temps
    SELECT
        g."stn",
        g."wban",
        COUNT(*) AS "valid_days_2019"
    FROM NOAA_DATA.NOAA_GSOD.GSOD2019 g
    JOIN candidate_stations s
      ON g."stn"  = s."stn"
     AND g."wban" = s."wban"
    WHERE g."temp" <  9000        -- exclude 9999.9 missing flag
      AND g."max"  <   900        -- exclude  999.9 missing flag
      AND g."min"  <   900
    GROUP BY g."stn", g."wban"
)
SELECT COUNT(*) AS "stations_reaching_90pct_of_2019_days"
FROM valid_2019
WHERE "valid_days_2019" >= 329;   -- 90 % of 365 days
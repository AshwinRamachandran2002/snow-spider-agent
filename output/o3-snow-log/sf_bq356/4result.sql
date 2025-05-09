WITH valid_stations AS (   -- stations operating from ≤2000-01-01 through ≥2019-06-30
    SELECT
        "usaf",
        "wban"
    FROM NOAA_DATA.NOAA_GSOD.STATIONS
    WHERE TRY_TO_DATE("begin",'YYYYMMDD') <= '2000-01-01'
      AND TRY_TO_DATE("end"  ,'YYYYMMDD') >= '2019-06-30'
),
daily_2019 AS (            -- 2019 records with non-missing temp/max/min
    SELECT
        g."stn"  AS usaf,
        g."wban" AS wban
    FROM NOAA_DATA.NOAA_GSOD.GSOD2019 AS g
    JOIN valid_stations               AS s
      ON g."stn"  = s."usaf"
     AND g."wban" = s."wban"
    WHERE g."temp" <> 9999.9
      AND g."max"  <> 9999.9
      AND g."min"  <> 9999.9
),
station_counts AS (        -- count valid-temperature days per station
    SELECT
        usaf,
        wban,
        COUNT(*) AS valid_days_2019
    FROM daily_2019
    GROUP BY usaf, wban
)
SELECT
    COUNT(*) AS stations_with_90pct_or_more_coverage_2019   -- ≥329 of 365 days
FROM station_counts
WHERE valid_days_2019 >= 329;
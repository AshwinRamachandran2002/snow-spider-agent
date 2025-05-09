WITH active_stations AS (
    /*  Stations whose period of record starts on or before
        2000-01-01 and extends through at least 2019-06-30      */
    SELECT
        TRIM("usaf") AS "usaf",
        TRIM("wban") AS "wban"
    FROM NOAA_DATA.NOAA_GSOD."STATIONS"
    WHERE "begin" <= '20000101'
      AND "end"   >= '20190630'
),
valid_days_2019 AS (
    /*  Count 2019 calendar-days with non-missing temp, max, min */
    SELECT
        TRIM("stn")  AS "usaf",
        TRIM("wban") AS "wban",
        COUNT(*)     AS "valid_day_cnt"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2019"
    WHERE "temp" IS NOT NULL AND "max" IS NOT NULL AND "min" IS NOT NULL
      AND "temp" < 9999          /* 9999.9 = missing sentinel           */
      AND "max"  < 9999
      AND "min"  < 9999
    GROUP BY TRIM("stn"), TRIM("wban")
),
stations_90pct_or_more AS (
    /*  Join to active stations and require ≥ 90 % of 365 days (≥ 329) */
    SELECT v.*
    FROM valid_days_2019 v
    JOIN active_stations a
      ON v."usaf" = a."usaf"
     AND v."wban" = a."wban"
    WHERE v."valid_day_cnt" >= 329      -- 0.90 × 365 rounded up
)
SELECT COUNT(*) AS "station_count_90pct_plus"
FROM stations_90pct_or_more;
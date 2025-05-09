WITH station_period AS (      -- stations whose record spans the required dates
    SELECT 
        "usaf"                       AS "stn",
        "wban",
        TO_DATE("begin", 'YYYYMMDD') AS begin_dt,
        TO_DATE("end"  , 'YYYYMMDD') AS end_dt
    FROM NOAA_DATA.NOAA_GSOD.STATIONS
    WHERE TO_DATE("begin", 'YYYYMMDD') <= DATE '2000-01-01'
      AND TO_DATE("end"  , 'YYYYMMDD') >= DATE '2019-06-30'
),
valid_2019 AS (               -- 2019 rows with all three temperature fields present
    SELECT 
        "stn",
        "wban",
        COUNT(*) AS valid_days
    FROM NOAA_DATA.NOAA_GSOD.GSOD2019
    WHERE "temp" <> 9999.9   -- non-missing daily mean temperature
      AND "max"  <> 9999.9   -- non-missing daily max
      AND "min"  <> 9999.9   -- non-missing daily min
    GROUP BY "stn", "wban"
),
eligible AS (                 -- stations meeting both criteria
    SELECT v.*
    FROM valid_2019 v
    JOIN station_period s
      ON v."stn"  = s."stn"
     AND v."wban" = s."wban"
),
max_days AS (                  -- best 2019 data-day count across eligible stations
    SELECT MAX(valid_days) AS max_valid_days
    FROM eligible
)
SELECT COUNT(*) AS "stations_ge_90pct_of_max_days"
FROM   eligible
JOIN   max_days
  ON   eligible.valid_days >= 0.90 * max_days.max_valid_days;
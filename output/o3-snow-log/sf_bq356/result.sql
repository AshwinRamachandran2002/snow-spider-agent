WITH candidate_stations AS (   -- stations whose POR starts ≤2000-01-01 and extends ≥2019-06-30
    SELECT 
        "usaf"  AS "stn",
        "wban",
        TO_DATE("begin", 'YYYYMMDD') AS "begin_date",
        TO_DATE("end"  , 'YYYYMMDD') AS "end_date"
    FROM NOAA_DATA.NOAA_GSOD.STATIONS
    WHERE TO_DATE("begin", 'YYYYMMDD') <= '2000-01-01'
      AND TO_DATE("end"  , 'YYYYMMDD') >= '2019-06-30'
),
valid_2019_days AS (          -- count of 2019 days with valid temp/max/min values
    SELECT
        "stn",
        "wban",
        COUNT(*) AS "valid_day_cnt"
    FROM NOAA_DATA.NOAA_GSOD.GSOD2019
    WHERE "temp" < 9999.9     -- eliminate missing sentinels
      AND "max"  < 9999.9
      AND "min"  < 9999.9
    GROUP BY "stn","wban"
),
qualified_stations AS (       -- need ≥90 % of 365 days ⇒ ≥329 valid records
    SELECT v."stn", v."wban"
    FROM valid_2019_days v
    JOIN candidate_stations c
      ON v."stn" = c."stn" AND v."wban" = c."wban"
    WHERE v."valid_day_cnt" >= 329
)
SELECT COUNT(*) AS "num_stations_meeting_90pct_criterion"
FROM qualified_stations;
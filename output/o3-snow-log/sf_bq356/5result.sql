WITH valid_stations AS (          -- stations whose period of record spans 1-Jan-2000 … 30-Jun-2019
    SELECT
        "usaf"   AS stn,
        "wban"
    FROM NOAA_DATA.NOAA_GSOD.STATIONS
    WHERE TRY_TO_NUMBER("begin") <= 20000101    -- began on/ before 1-Jan-2000
      AND TRY_TO_NUMBER("end")   >= 20190630    -- still reporting on/ after 30-Jun-2019
),

daily_valid_2019 AS (             -- count 2019 days with non-missing temps
    SELECT
        "stn",
        "wban",
        COUNT(*) AS valid_days
    FROM NOAA_DATA.NOAA_GSOD.GSOD2019
    WHERE "temp" <  9999          -- non-missing daily mean temp
      AND "max"  <  9999          -- non-missing daily max temp
      AND "min"  <  9999          -- non-missing daily min temp
    GROUP BY "stn", "wban"
),

stations_90pct AS (               -- need at least 90 % of 365 (≥ 329) valid days
    SELECT d."stn", d."wban"
    FROM  daily_valid_2019 d
    JOIN  valid_stations   s
      ON  d."stn"  = s.stn
      AND d."wban" = s."wban"
    WHERE d.valid_days >= 329
)

SELECT COUNT(*) AS "stations_meeting_90pct_threshold"
FROM   stations_90pct;
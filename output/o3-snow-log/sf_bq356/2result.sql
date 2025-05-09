WITH stations_eligible AS (
    SELECT 
        "usaf"  AS "stn",
        "wban",
        TRY_TO_NUMBER("begin") AS "begin_date",
        TRY_TO_NUMBER("end")   AS "end_date"
    FROM NOAA_DATA.NOAA_GSOD.STATIONS
    WHERE TRY_TO_NUMBER("begin") <= 20000101      -- began on or before 01-Jan-2000
      AND TRY_TO_NUMBER("end")   >= 20190630      -- continued through at least 30-Jun-2019
), 
valid_2019 AS (
    SELECT 
        "stn",
        "wban",
        COUNT(*) AS valid_days_2019
    FROM NOAA_DATA.NOAA_GSOD.GSOD2019
    WHERE "temp" <  9999      -- exclude placeholder / missing values
      AND "max"  <  9999
      AND "min"  <  9999
    GROUP BY "stn", "wban"
)
SELECT COUNT(*) AS stations_meeting_90pct_rule
FROM valid_2019  v
JOIN stations_eligible s
  ON v."stn"  = s."stn"
 AND v."wban" = s."wban"
WHERE v.valid_days_2019 >= 0.9 * 365;  -- at least 90 % of 2019’s 365 days
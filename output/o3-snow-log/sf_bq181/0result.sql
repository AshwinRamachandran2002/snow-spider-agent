WITH valid_day_counts AS (   -- how many 2022 days have GOOD data for each station
    SELECT
        "stn"                                                        AS station_id ,
        COUNT ( DISTINCT                                                -- distinct calendar days
                TO_DATE(
                    "year" || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0') ,
                    'YYYY-MM-DD')
             )                                                        AS valid_days_2022
    FROM NOAA_DATA.NOAA_GSOD.GSOD2022
    WHERE  "stn" <> '999999'                 -- valid USAF/USAF-like id
      AND  "temp" IS NOT NULL AND "temp" <> 9999.9
      AND  "max"  IS NOT NULL AND "max"  <> 9999.9
      AND  "min"  IS NOT NULL AND "min"  <> 9999.9
    GROUP BY "stn"
),
stations_meeting_90pct AS (          -- stations with ≥90 % (≥329) good-data days
    SELECT station_id
    FROM   valid_day_counts
    WHERE  valid_days_2022 >= 0.9 * 365        -- 2022 is not a leap-year
),
total_station_pool AS (              -- all stations in GSOD catalogue w/ real id
    SELECT COUNT(DISTINCT "usaf") AS total_stations
    FROM   NOAA_DATA.NOAA_GSOD.STATIONS
    WHERE  "usaf" <> '999999'
)
SELECT
    ROUND(
        ( SELECT COUNT(*)::FLOAT FROM stations_meeting_90pct )  -- numerator
        /
        ( SELECT total_stations        FROM total_station_pool) -- denominator
        * 100 ,                                                 -- to percent
        2                                                       -- 2-dec places
    ) AS "PERCENT_OF_STATIONS_WITH_>=90PCT_VALID_TEMPS_2022"
;
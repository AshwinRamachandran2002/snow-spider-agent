WITH daily_valid AS (           -- all GSOD 2022 rows with good temperature data
    SELECT
        "stn",                                             -- USAF id in the daily file
        TO_DATE("year"||'-'||"mo"||'-'||"da") AS obs_date
    FROM NOAA_DATA.NOAA_GSOD."GSOD2022"
    WHERE "stn" <> '999999'                                -- ignore invalid station ids
      AND "temp" IS NOT NULL AND "max" IS NOT NULL AND "min" IS NOT NULL
      AND "temp" <> 9999.9   AND "max" <> 9999.9   AND "min" <> 9999.9
),
valid_counts AS (          -- count of valid-data days per station
    SELECT
        "stn",
        COUNT(DISTINCT obs_date) AS valid_day_cnt
    FROM daily_valid
    GROUP BY "stn"
),
qualifying_stations AS (   -- stations with ≥90 % of 2022 days (365) valid
    SELECT "stn"
    FROM valid_counts
    WHERE valid_day_cnt >= 0.9 * 365
),
all_stations AS (          -- every station listed in the GSOD metadata file
    SELECT DISTINCT "usaf" AS stn
    FROM NOAA_DATA.NOAA_GSOD."STATIONS"
    WHERE "usaf" <> '999999'
)
SELECT
    ROUND( 100.0 * (SELECT COUNT(*) FROM qualifying_stations)
                 / (SELECT COUNT(*) FROM all_stations)
          , 2)  AS "PERCENT_STATIONS_WITH_≥90PCT_VALID_TEMP_2022"
;
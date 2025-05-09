WITH eligible_stations AS (   -- stations whose period of record meets the date-range criteria
    SELECT
        "usaf"  AS "stn",
        "wban"
    FROM NOAA_DATA.NOAA_GSOD."STATIONS"
    WHERE
        TRY_TO_DATE("begin", 'YYYYMMDD') <= '2000-01-01'
        AND TRY_TO_DATE("end"  , 'YYYYMMDD') >= '2019-06-30'
),
station_2019_counts AS (      -- how many 2019 days have all three temperatures present
    SELECT
        "stn",
        "wban",
        COUNT(*) AS "valid_days_2019"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2019"
    WHERE
          "temp" IS NOT NULL AND "max" IS NOT NULL AND "min" IS NOT NULL
      AND "temp" <> 9999.9     -- GSOD missing value flag
      AND "max"  <> 9999.9
      AND "min"  <> 9999.9
    GROUP BY "stn", "wban"
),
qualified AS (                -- stations that meet the 90 % threshold
    SELECT c.*
    FROM station_2019_counts c
    JOIN eligible_stations  e
      ON c."stn" = e."stn" AND c."wban" = e."wban"
    WHERE c."valid_days_2019" >= CEIL(0.9 * 365)   -- ≥ 329 valid days
)
SELECT COUNT(*) AS "stations_meeting_90pct_requirement"
FROM qualified;
WITH valid_days_per_station AS (   /* count valid 2022 daily records per station */
    SELECT
        g."stn"                                   AS "usaf",
        COUNT(*)                                  AS "valid_day_count"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2022"  g
    JOIN NOAA_DATA.NOAA_GSOD."STATIONS"  s
          ON s."usaf" = g."stn"
    WHERE s."usaf" <> '999999'                   -- exclude invalid station codes
      AND g."temp" IS NOT NULL AND g."temp" <> 9999.9
      AND g."max"  IS NOT NULL AND g."max"  <> 9999.9
      AND g."min"  IS NOT NULL AND g."min"  <> 9999.9
    GROUP BY g."stn"
),
meets_90pct_requirement AS (        /* stations with ≥90 % valid days (328.5 ≈ 0.9*365) */
    SELECT "usaf"
    FROM   valid_days_per_station
    WHERE  "valid_day_count" >= 0.9 * 365
),
totals AS (                          /* total stations vs. qualifying stations */
    SELECT
        COUNT(DISTINCT CASE WHEN "usaf" <> '999999' THEN "usaf" END) AS total_stations,
        (SELECT COUNT(*) FROM meets_90pct_requirement)               AS qualifying_stations
    FROM NOAA_DATA.NOAA_GSOD."STATIONS"
)
SELECT
    ROUND( 100.0 * qualifying_stations / total_stations , 2 ) AS "pct_stations_with_valid_temps_2022_90pct"
FROM totals;
/*  Percentage of stations that reported valid temperature data
    on at least 90 % of the days in 2022                         */

WITH station_daily AS (      -- daily counts per station
    SELECT
        "stn"                                AS "station_id",
        COUNT(*)                             AS "total_days",
        SUM(
            CASE
                WHEN "temp" IS NOT NULL AND "temp" <> 9999.9
                 AND "max"  IS NOT NULL AND "max"  <> 9999.9
                 AND "min"  IS NOT NULL AND "min"  <> 9999.9
                THEN 1 ELSE 0
            END
        )                                   AS "valid_days"
    FROM NOAA_DATA.NOAA_GSOD.GSOD2022
    WHERE "stn" <> '999999'                 -- exclude invalid USAF codes
    GROUP BY "stn"
),
station_ratio AS (          -- ratio of valid days per station
    SELECT
        "station_id",
        "valid_days",
        "total_days",
        CASE 
            WHEN "total_days" > 0 
            THEN "valid_days"::FLOAT / "total_days" 
            ELSE 0 
        END                               AS "valid_ratio"
    FROM station_daily
),
summary AS (                -- how many meet the 90 % rule
    SELECT
        COUNT(*)                                          AS "total_stations",
        SUM(CASE WHEN "valid_ratio" >= 0.9 THEN 1 ELSE 0 END) 
                                                         AS "stations_meeting"
    FROM station_ratio
)
SELECT
    ROUND("stations_meeting"::FLOAT / "total_stations" * 100, 4) 
        AS "percentage_of_stations_meeting_criteria"
FROM summary;
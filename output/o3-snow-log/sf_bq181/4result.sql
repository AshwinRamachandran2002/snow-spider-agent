/* percentage of stations that reported valid temperature data
   (temp, max, min not NULL/9999.9) on ≥ 90 % (≥329) of the 365 days in 2022 */
WITH valid_days_per_station AS (
    SELECT
        g."stn",
        COUNT(DISTINCT DATE_FROM_PARTS(g."year"::INT , g."mo"::INT , g."da"::INT))     AS valid_day_cnt
    FROM  NOAA_DATA.NOAA_GSOD."GSOD2022"  AS g
    WHERE g."temp" IS NOT NULL  AND g."max" IS NOT NULL  AND g."min" IS NOT NULL
      AND g."temp" <> 9999.9    AND g."max" <> 9999.9    AND g."min" <> 9999.9
    GROUP BY g."stn"
),
stations_meeting_90pct AS (
    SELECT "stn"
    FROM   valid_days_per_station
    WHERE  valid_day_cnt >= 0.9 * 365        -- at least 329 days
),
all_stations AS (                         -- all GSOD stations with a valid USAF id
    SELECT DISTINCT s."usaf" AS stn
    FROM   NOAA_DATA.NOAA_GSOD."STATIONS" s
    WHERE  s."usaf" <> '999999'
)
SELECT
    ROUND( 100.0 * (SELECT COUNT(*) FROM stations_meeting_90pct)
                 / NULLIF((SELECT COUNT(*) FROM all_stations),0)
         , 2)                                  AS "PCT_STATIONS_WITH_90PCT_VALID_2022"
;
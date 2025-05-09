WITH valid_days AS (   -- count valid–data days for each station in 2022
    SELECT
        g."stn"                               AS "usaf",
        COUNT(DISTINCT DATE_FROM_PARTS(        -- unique calendar days
                TO_NUMBER(g."year"),
                TO_NUMBER(g."mo"),
                TO_NUMBER(g."da")
        ))                                    AS "valid_day_cnt"
    FROM NOAA_DATA.NOAA_GSOD.GSOD2022 g
    JOIN NOAA_DATA.NOAA_GSOD.STATIONS  s
          ON g."stn" = s."usaf"
    WHERE s."usaf" <> '999999'                -- valid identifier
      AND g."temp" IS NOT NULL AND g."max" IS NOT NULL AND g."min" IS NOT NULL
      AND g."temp" <> 9999.9  AND g."max" <> 9999.9  AND g."min" <> 9999.9
    GROUP BY g."stn"
),
passed AS (                                   -- stations meeting 90 %-of-days rule
    SELECT "usaf"
    FROM   valid_days
    WHERE  "valid_day_cnt" >= CEIL(365*0.90)  -- 329 days in 2022
),
totals AS (                                   -- total available stations
    SELECT
        COUNT(DISTINCT "usaf")                AS "all_station_cnt"
    FROM NOAA_DATA.NOAA_GSOD.STATIONS
    WHERE "usaf" <> '999999'
)
SELECT
    ROUND( (SELECT COUNT(*) FROM passed)
           * 100.0
           / (SELECT "all_station_cnt" FROM totals)
         , 2)                                AS "percentage_of_stations"
;
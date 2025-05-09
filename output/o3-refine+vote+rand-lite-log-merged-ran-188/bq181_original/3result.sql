-- percentage of GSOD stations whose 2022 records contain valid
-- (non‑null and not 9999.9) temperature, max and min values
-- on at least 90 % of the calendar days (≥ 329 of 365)

WITH
-- 1.  Daily‑quality assessment for every station in 2022
station_day_quality AS (
  SELECT
    stn                                AS usaf,
    COUNTIF( temp IS NOT NULL
             AND temp != 9999.9
             AND `max` IS NOT NULL AND `max` != 9999.9
             AND `min` IS NOT NULL AND `min` != 9999.9 )   AS good_days
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE stn <> '999999'                                   -- ignore invalid id
  GROUP BY stn
),

-- 2.  Stations meeting the ≥90 % (≥329 days) criterion
qualified_stations AS (
  SELECT usaf
  FROM station_day_quality
  WHERE good_days >= 0.9 * 365            -- 2022 is not a leap year
),

-- 3.  Universe of “available” GSOD stations (valid id in stations table)
all_stations AS (
  SELECT DISTINCT usaf
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE usaf <> '999999'                  -- exclude invalid identifier
)

-- 4.  Final percentage
SELECT
  ROUND( 100.0 *
         (SELECT COUNT(*)  FROM qualified_stations) /
         (SELECT COUNT(*)  FROM all_stations)
       , 4) AS pct_stations_with_90pct_valid_temps_2022;
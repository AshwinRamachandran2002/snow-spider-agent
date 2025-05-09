-- Percentage of GSOD weather stations that reported
-- NON‑missing / valid temperature, maximum and minimum
-- values on at least 90 % of the days in calendar‑year 2022
-- ( ≥ 329 out of 365 days ), considering only stations whose
-- USAF identifier is not the placeholder “999999”.

WITH all_stations AS (
  SELECT DISTINCT usaf
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE usaf IS NOT NULL
    AND usaf <> '999999'          -- keep only real stations
),
valid_daily_obs AS (
  SELECT
    stn AS usaf,
    COUNT(DISTINCT DATE(2022,
                        CAST(mo AS INT64),
                        CAST(da AS INT64))) AS valid_day_count
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE temp IS NOT NULL AND max IS NOT NULL AND min IS NOT NULL
        AND temp <> 9999.9 AND max <> 9999.9 AND min <> 9999.9
  GROUP BY stn
),
qualified_stations AS (
  SELECT usaf
  FROM valid_daily_obs
  WHERE valid_day_count >= 329      -- ≥ 90 % of 365 days
)

SELECT
  ROUND(
    SAFE_DIVIDE(
      (SELECT COUNT(*) FROM qualified_stations) ,
      (SELECT COUNT(*) FROM all_stations)
    ) * 100
  , 2) AS pct_stations_with_90pct_valid_2022
;
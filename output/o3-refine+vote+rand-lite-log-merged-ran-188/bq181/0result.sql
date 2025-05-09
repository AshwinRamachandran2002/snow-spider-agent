-- Percentage of GSOD stations that had valid (non-missing, non-9999.9) temp/max/min 
-- values on at least 90 % of the days in 2022
WITH valid_2022 AS (
  -- Stations meeting the 90 % validity requirement
  SELECT
    stn
  FROM (
    SELECT
      stn,
      COUNTIF(
        temp IS NOT NULL AND max IS NOT NULL AND min IS NOT NULL
        AND temp <> 9999.9 AND max <> 9999.9 AND min <> 9999.9
      ) AS valid_days
    FROM `bigquery-public-data.noaa_gsod.gsod2022`
    GROUP BY stn
  )
  WHERE valid_days >= 0.90 * 365          -- ≥90 % of the year
),
all_stations AS (
  -- All GSOD stations with a real USAF identifier
  SELECT DISTINCT usaf
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE usaf IS NOT NULL
    AND usaf <> '999999'
)
SELECT
  ROUND(
    SAFE_DIVIDE(
      (SELECT COUNT(DISTINCT stn)  FROM valid_2022),
      (SELECT COUNT(DISTINCT usaf) FROM all_stations)
    ) * 100,
    4
  ) AS pct_stations_with_90pct_valid_temps_2022;
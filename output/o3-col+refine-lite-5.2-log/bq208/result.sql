-- Weather stations within 20 miles of Chappaqua, NY (41.197 °N, ‑73.764 °E)
-- with count of valid (≠ 9999.9) temperature observations during 2011‑2020
WITH nearby AS (
  SELECT
    usaf,
    wban,
    TRIM(name)                              AS station_name,
    ROUND(
      ST_DISTANCE(
        ST_GEOGPOINT(lon , lat),
        ST_GEOGPOINT(-73.764 , 41.197)
      ) / 1609.344,                         -- metres → miles
      2
    )                                       AS distance_miles
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE lat IS NOT NULL
    AND lon IS NOT NULL
    AND ST_DWITHIN(
          ST_GEOGPOINT(lon , lat),
          ST_GEOGPOINT(-73.764 , 41.197),
          32187                              -- 20 miles in metres
        )
),
obs AS (                                    -- 2011‑2020 GSOD rows
  SELECT
    stn,
    wban,
    temp
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX IN ('11','12','13','14','15','16','17','18','19','20')
    AND temp <> 9999.9                      -- exclude invalid temps
),
valid_counts AS (
  SELECT
    stn  AS usaf,
    wban,
    COUNT(*) AS valid_temp_obs
  FROM obs
  GROUP BY usaf, wban
)
SELECT
  n.station_name,
  n.usaf,
  n.wban,
  n.distance_miles,
  COALESCE(vc.valid_temp_obs, 0) AS valid_temperature_observations_2011_2020
FROM nearby n
LEFT JOIN valid_counts vc
  ON n.usaf = vc.usaf
 AND n.wban = vc.wban
ORDER BY valid_temperature_observations_2011_2020 DESC,
         n.station_name;
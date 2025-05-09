-- Weather stations within 20 miles (≈ 32 187 m) of Chappaqua, NY
-- and their counts of valid (temp ≠ 9999.9) temperature observations
-- recorded during calendar-years 2011-2020

SELECT
  CONCAT(s.usaf, '-', s.wban)              AS station_id,
  TRIM(s.name)                             AS station_name,
  ROUND(s.lat, 3)                          AS latitude,
  ROUND(s.lon, 3)                          AS longitude,
  COUNT(*)                                 AS valid_temp_obs_2011_2020
FROM `bigquery-public-data.noaa_gsod.gsod*` AS g
JOIN `bigquery-public-data.noaa_gsod.stations` AS s
  ON g.stn  = s.usaf
 AND g.wban = s.wban
WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'          -- restrict to years 2011-2020
  AND ST_DWITHIN(                                      -- within 20 miles of Chappaqua
        ST_GEOGPOINT(s.lon, s.lat),
        ST_GEOGPOINT(-73.764, 41.197),
        32187                                          -- metres
      )
  AND g.temp != 9999.9                                 -- exclude missing temperature values
GROUP BY station_id, station_name, latitude, longitude
HAVING valid_temp_obs_2011_2020 > 0                    -- keep stations with at least one record
ORDER BY valid_temp_obs_2011_2020 DESC;
-- Weather stations ≤ 20 mi from Chappaqua, NY (41.197 N, –73.764 E)
-- with counts of valid temperature days recorded from 2011-2020
WITH near AS (
  SELECT
    usaf,
    wban,
    name                                         AS station_name,
    ROUND(
      ST_DISTANCE(
        ST_GEOGPOINT(lon , lat),
        ST_GEOGPOINT(-73.764 , 41.197)
      ) / 1609.34 , 2)                          AS distance_miles
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE lat IS NOT NULL
    AND lon IS NOT NULL
    AND ST_DWITHIN(
          ST_GEOGPOINT(lon , lat),
          ST_GEOGPOINT(-73.764 , 41.197),
          32187                                   -- 20 miles in metres
        )
),
obs AS (
  SELECT
    stn  AS usaf,
    wban,
    COUNT(*) AS valid_temp_obs_2011_2020
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'
    AND temp <> 9999.9        -- exclude missing temperatures
    AND count_temp > 0        -- require at least one observation
  GROUP BY usaf, wban
)
SELECT
  n.usaf,
  n.wban,
  n.station_name,
  n.distance_miles,
  IFNULL(o.valid_temp_obs_2011_2020, 0) AS valid_temp_obs_2011_2020
FROM near n
LEFT JOIN obs o USING (usaf, wban)
ORDER BY distance_miles;
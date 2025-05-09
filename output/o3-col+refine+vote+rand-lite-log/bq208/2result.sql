-- Weather-stations within 20 miles (~32 186 m) of Chappaqua, NY  
-- together with the count of VALID (≠ 9999.9) daily mean-temperature
-- observations recorded between 2011 and 2020 inclusively.
WITH near_stations AS (
  SELECT
    usaf,
    wban,
    name,
    lat,
    lon
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE lat IS NOT NULL
    AND lon IS NOT NULL
    AND ST_DWITHIN(
          ST_GEOGPOINT(lon, lat),          -- station location
          ST_GEOGPOINT(-73.764, 41.197),   -- Chappaqua, NY
          32186                             -- 20 miles in metres
        )
),
temp_counts AS (
  SELECT
    g.stn  AS usaf,
    g.wban AS wban,
    SUM(CASE WHEN g.temp <> 9999.9 THEN 1 ELSE 0 END) AS valid_temp_2011_2020
  FROM `bigquery-public-data.noaa_gsod.gsod*` AS g
  JOIN near_stations AS n
    ON g.stn  = n.usaf
   AND g.wban = n.wban
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'         -- pick years
  GROUP BY usaf, wban
)
SELECT
  n.usaf,
  n.wban,
  n.name,
  n.lat,
  n.lon,
  c.valid_temp_2011_2020
FROM near_stations AS n
LEFT JOIN temp_counts AS c USING (usaf, wban)
ORDER BY c.valid_temp_2011_2020 DESC;
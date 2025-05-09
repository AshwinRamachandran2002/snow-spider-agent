/*  Weather stations ≤ 20 miles from Chappaqua, NY (41.197 ° N, -73.764 ° W)
    and their count of *valid* temperature observations (2011-2020).

    – a “valid” row has  temp <> 9999.9  and  count_temp > 0           */

WITH stations_within_20_miles AS (
  SELECT
    usaf              AS stn ,
    wban ,
    name              AS station_name ,
    lat ,
    lon ,
    ST_DISTANCE( ST_GEOGPOINT(lon , lat) ,
                 ST_GEOGPOINT(-73.764 , 41.197) ) / 1609.344  AS distance_miles   -- convert to miles
  FROM  `bigquery-public-data.noaa_gsod.stations`
  WHERE lat IS NOT NULL
    AND lon IS NOT NULL
    AND ST_DWITHIN( ST_GEOGPOINT(lon , lat) ,
                    ST_GEOGPOINT(-73.764 , 41.197) ,
                    32187 )          -- 20 miles in metres
),

gsod_2011_2020 AS (
  SELECT
    stn ,
    wban ,
    temp ,
    count_temp
  FROM  `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX IN ('2011','2012','2013','2014','2015',
                          '2016','2017','2018','2019','2020')
)

SELECT
  s.station_name ,
  s.stn             AS usaf ,
  s.wban ,
  ROUND(s.distance_miles , 2) AS miles_from_chappaqua ,
  COUNT(*)          AS valid_temperature_observations_2011_2020
FROM        gsod_2011_2020 AS g
INNER JOIN  stations_within_20_miles AS s
       ON   g.stn  = s.stn
      AND   g.wban = s.wban
WHERE g.temp       <> 9999.9
  AND g.count_temp > 0
GROUP BY
  s.station_name ,
  usaf ,
  s.wban ,
  miles_from_chappaqua
ORDER BY
  miles_from_chappaqua;
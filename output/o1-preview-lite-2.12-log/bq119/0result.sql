SELECT 
  CONCAT('POINT(', ROUND(longitude, 4), ' ', ROUND(latitude, 4), ')') AS geom,
  COALESCE(ROUND(SUM(segment_distance) OVER (ORDER BY iso_time), 4), 0.0000) AS cumulative_distance_meters,
  wmo_wind
FROM (
  SELECT 
    iso_time,
    longitude,
    latitude,
    wmo_wind,
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(
        LAG(longitude) OVER (ORDER BY iso_time),
        LAG(latitude) OVER (ORDER BY iso_time)
      )
    ) AS segment_distance
  FROM 
    `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE 
    sid = '2020233N14313'
  ORDER BY 
    iso_time
)
ORDER BY 
  iso_time;
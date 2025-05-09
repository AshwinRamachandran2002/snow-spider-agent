WITH atlantic_2020 AS (
  -- North‑Atlantic hurricane points for the 2020 season
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    -- distance (m) from previous point in the same storm track
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(
        LAG(longitude)  OVER (PARTITION BY sid ORDER BY iso_time),
        LAG(latitude)   OVER (PARTITION BY sid ORDER BY iso_time)
      )
    ) AS segment_dist_m
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'        -- North Atlantic basin
    AND latitude  IS NOT NULL
    AND longitude IS NOT NULL
),
track_distance AS (
  -- total travelled distance per hurricane
  SELECT
    sid,
    SUM(segment_dist_m) AS total_distance_m
  FROM atlantic_2020
  GROUP BY sid
),
second_longest AS (
  -- identify the hurricane with the 2nd‑longest track
  SELECT sid
  FROM (
    SELECT
      sid,
      total_distance_m,
      DENSE_RANK() OVER (ORDER BY total_distance_m DESC) AS rnk
    FROM track_distance
  )
  WHERE rnk = 2
  LIMIT 1
),
final_coord AS (
  -- final (latest) position of that hurricane
  SELECT
    latitude
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE sid IN (SELECT sid FROM second_longest)
  ORDER BY iso_time DESC
  LIMIT 1
)
SELECT latitude
FROM final_coord;
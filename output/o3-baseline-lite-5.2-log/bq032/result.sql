WITH track AS (
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    ST_GEOGPOINT(longitude, latitude) AS geog_pt
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'          -- North Atlantic storms
    AND latitude  IS NOT NULL
    AND longitude IS NOT NULL
),
step_distances AS (
  SELECT
    sid,
    iso_time,
    latitude,
    ST_DISTANCE(
      geog_pt,
      LAG(geog_pt) OVER (PARTITION BY sid ORDER BY iso_time)
    ) AS leg_dist_m,
    ROW_NUMBER() OVER (PARTITION BY sid ORDER BY iso_time DESC) AS r_desc
  FROM track
),
storm_totals AS (
  SELECT
    sid,
    SUM(leg_dist_m) AS total_distance_m,
    MAX(CASE WHEN r_desc = 1 THEN latitude END) AS final_latitude
  FROM step_distances
  GROUP BY sid
),
ranked AS (
  SELECT
    *,
    DENSE_RANK() OVER (ORDER BY total_distance_m DESC) AS dist_rank
  FROM storm_totals
)
SELECT
  final_latitude
FROM ranked
WHERE dist_rank = 2;
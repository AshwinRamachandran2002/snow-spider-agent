WITH atl_2020 AS (
  -- All 2020 North‑Atlantic storm positions
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    ST_GEOGPOINT(longitude, latitude) AS geom
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin = 'NA'
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL
),
leg_lengths AS (
  -- Distance between successive fixes for each storm
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    ST_DISTANCE(
      geom,
      LAG(geom) OVER (PARTITION BY sid ORDER BY iso_time)
    ) AS segment_m
  FROM atl_2020
),
track_totals AS (
  -- Total travel distance per storm
  SELECT
    sid,
    SUM(IFNULL(segment_m, 0)) AS total_distance_m
  FROM leg_lengths
  GROUP BY sid
),
second_longest_sid AS (
  -- SID of the storm with the 2nd‑longest track
  SELECT sid
  FROM track_totals
  ORDER BY total_distance_m DESC
  LIMIT 1 OFFSET 1            -- LIMIT first, then OFFSET in BigQuery
)
-- Latitude of the final reported position for that storm
SELECT latitude
FROM atl_2020
WHERE sid = (SELECT sid FROM second_longest_sid)
ORDER BY iso_time DESC
LIMIT 1;
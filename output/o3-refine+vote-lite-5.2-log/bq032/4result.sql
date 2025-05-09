WITH atlantic_2020 AS (
  -- 1. 2020 storms in the North Atlantic
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    ST_GEOGPOINT(longitude, latitude) AS pt
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'          -- North Atlantic basin
),

segments AS (
  -- 2. distance between successive fixes for each storm
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    ST_DISTANCE(
      pt,
      LAG(pt) OVER (PARTITION BY sid ORDER BY iso_time)
    ) AS seg_km          -- metres, but units cancel in ranking
  FROM atlantic_2020
),

tracks AS (
  -- 3. total travelled distance per storm
  SELECT
    sid,
    SUM(seg_km) AS total_dist_m
  FROM segments
  GROUP BY sid
),

second_longest_sid AS (
  -- 4. identify storm with the 2nd‑longest path
  SELECT sid
  FROM (
    SELECT
      sid,
      total_dist_m,
      ROW_NUMBER() OVER (ORDER BY total_dist_m DESC, sid) AS rnk
    FROM tracks
  )
  WHERE rnk = 2
),

final_fix AS (
  -- 5. last (final) coordinate of that storm
  SELECT
    latitude,
    ROW_NUMBER() OVER (ORDER BY iso_time DESC) AS rnk
  FROM atlantic_2020
  WHERE sid IN (SELECT sid FROM second_longest_sid)
)

-- 6. return the latitude of the final coordinate
SELECT latitude
FROM final_fix
WHERE rnk = 1;
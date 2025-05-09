-- Hurricane track with the 3rd–longest path in the North Atlantic, season 2020
WITH atlantic_2020 AS (
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    wmo_wind                       -- maximum sustained wind (knots)
  FROM
    `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE
    basin = 'NA'                   -- North Atlantic basin
    AND EXTRACT(YEAR FROM iso_time) = 2020
),

-- distance between successive fixes (km)
track_segments AS (
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    wmo_wind,
    -- distance from previous fix (first fix gets 0)
    COALESCE(
      ST_DISTANCE(
        ST_GEOGPOINT(longitude, latitude),
        ST_GEOGPOINT(
          LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time),
          LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)
        )
      ) / 1000,                   -- metres → km
      0
    ) AS segment_km
  FROM atlantic_2020
),

-- cumulative distance for each fix
cumulative_tracks AS (
  SELECT
    sid,
    name,
    iso_time,
    latitude,
    longitude,
    wmo_wind,
    SUM(segment_km) OVER (
      PARTITION BY sid
      ORDER BY iso_time
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_km
  FROM track_segments
),

-- total travel distance per storm
storm_totals AS (
  SELECT
    sid,
    name,
    MAX(cumulative_km) AS total_km
  FROM cumulative_tracks
  GROUP BY sid, name
),

-- rank storms by total distance
ranked_storms AS (
  SELECT
    sid,
    name,
    total_km,
    DENSE_RANK() OVER (ORDER BY total_km DESC) AS dist_rank
  FROM storm_totals
)

-- final output: fixes for the storm with the 3‑rd longest path
SELECT
  ct.sid,
  rs.name,
  ct.iso_time,
  ct.latitude,
  ct.longitude,
  ROUND(ct.cumulative_km, 2) AS cumulative_distance_km,
  ct.wmo_wind AS max_sustained_wind_knots
FROM cumulative_tracks AS ct
JOIN ranked_storms  AS rs
  USING (sid)
WHERE rs.dist_rank = 3
ORDER BY ct.iso_time;
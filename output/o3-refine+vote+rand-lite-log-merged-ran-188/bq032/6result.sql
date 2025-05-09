WITH atl2020 AS (
  -- 2020 tracks in the North Atlantic basin
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    ST_GEOGPOINT(longitude, latitude) AS geom
  FROM
    `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE
    season = '2020'
    AND basin = 'NA'              -- North Atlantic
    AND track_type = 'main'       -- main track only
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL
),
-- distance between consecutive fixes for each storm
dists AS (
  SELECT
    sid,
    ST_DISTANCE(
      geom,
      LAG(geom) OVER (PARTITION BY sid ORDER BY iso_time)
    ) AS segment_m
  FROM atl2020
),
-- total path length per storm
totals AS (
  SELECT
    sid,
    SUM(segment_m) / 1000 AS total_km   -- convert to kilometres
  FROM dists
  GROUP BY sid
),
-- rank storms by path length (longest = 1)
ranked AS (
  SELECT
    sid,
    total_km,
    ROW_NUMBER() OVER (ORDER BY total_km DESC, sid) AS rnk
  FROM totals
),
-- storm with the 2nd‑longest path
second_longest AS (
  SELECT sid
  FROM ranked
  WHERE rnk = 2
),
-- final (latest) position of that storm
final_fix AS (
  SELECT
    a.sid,
    ARRAY_AGG(a.latitude ORDER BY a.iso_time DESC LIMIT 1)[OFFSET(0)] AS latitude_final
  FROM atl2020 a
  JOIN second_longest s USING (sid)
  GROUP BY a.sid
)
SELECT latitude_final AS latitude
FROM final_fix;
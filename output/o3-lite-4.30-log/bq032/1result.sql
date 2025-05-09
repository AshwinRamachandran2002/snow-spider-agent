SELECT ROUND(latitude, 4) AS latitude
FROM (
  WITH points AS (
    SELECT
      sid,
      iso_time,
      ST_GEOGPOINT(longitude, latitude) AS geom
    FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
    WHERE season = '2020'
      AND basin  = 'NA'
      AND latitude IS NOT NULL
      AND longitude IS NOT NULL
  ),
  segments AS (
    SELECT
      sid,
      ST_DISTANCE(
        geom,
        LAG(geom) OVER (PARTITION BY sid ORDER BY iso_time)
      ) AS seg_m
    FROM points
  ),
  totals AS (
    SELECT
      sid,
      SUM(seg_m) AS total_m
    FROM segments
    GROUP BY sid
  ),
  second_longest AS (
    SELECT sid
    FROM (
      SELECT
        sid,
        ROW_NUMBER() OVER (ORDER BY total_m DESC) AS rn
      FROM totals
    )
    WHERE rn = 2
  ),
  last_fix AS (
    SELECT
      h.sid,
      h.latitude,
      ROW_NUMBER() OVER (PARTITION BY h.sid ORDER BY h.iso_time DESC) AS rn
    FROM `bigquery-public-data.noaa_hurricanes.hurricanes` AS h
    JOIN second_longest USING (sid)
  )
  SELECT latitude
  FROM last_fix
  WHERE rn = 1
)
WITH atl2020 AS (
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    ST_GEOGPOINT(longitude, latitude) AS geom
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
),
segments AS (
  SELECT
    sid,
    ST_DISTANCE(
      geom,
      LAG(geom) OVER (PARTITION BY sid ORDER BY iso_time)
    ) AS step_m
  FROM atl2020
),
totals AS (
  SELECT
    sid,
    SUM(step_m) / 1000 AS track_km          -- distance in kilometres
  FROM segments
  GROUP BY sid
),
second_longest AS (                       -- hurricane ranked 2nd by travelled distance
  SELECT sid
  FROM (
    SELECT
      sid,
      track_km,
      DENSE_RANK() OVER (ORDER BY track_km DESC) AS rk
    FROM totals
  )
  WHERE rk = 2
),
final_point AS (                          -- last reported position of that hurricane
  SELECT
    a.sid,
    ARRAY_AGG(a.latitude ORDER BY a.iso_time DESC LIMIT 1)[OFFSET(0)] AS final_lat
  FROM atl2020 AS a
  JOIN second_longest USING (sid)
  GROUP BY a.sid
)
SELECT final_lat
FROM final_point;
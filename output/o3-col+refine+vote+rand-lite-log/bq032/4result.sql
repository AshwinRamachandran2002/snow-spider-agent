WITH seg AS (
  SELECT
    sid,
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(
        LEAD(longitude) OVER (PARTITION BY sid ORDER BY iso_time),
        LEAD(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)
      )
    ) / 1000 AS km_segment
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
),
tot AS (
  SELECT sid, SUM(km_segment) AS total_km
  FROM seg
  WHERE km_segment IS NOT NULL
  GROUP BY sid
),
last_pt AS (
  SELECT DISTINCT
    sid,
    LAST_VALUE(latitude) OVER (
      PARTITION BY sid ORDER BY iso_time
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_lat
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020'
    AND basin  = 'NA'
),
ranked AS (
  SELECT
    t.sid,
    l.last_lat,
    DENSE_RANK() OVER (ORDER BY t.total_km DESC) AS rnk
  FROM tot t
  JOIN last_pt l USING (sid)
)
SELECT last_lat AS latitude_of_final_coordinates
FROM ranked
WHERE rnk = 2;
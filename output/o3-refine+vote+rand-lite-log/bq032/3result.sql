WITH atl_2020 AS (
  -- 2020 North‑Atlantic best‑track positions
  SELECT
    sid,
    iso_time,
    latitude,
    longitude
  FROM
    `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE
    season = '2020'
    AND basin  = 'NA'          -- North Atlantic basin
    AND iso_time IS NOT NULL   -- ensure ordering field present
),
path_dist AS (
  -- distance between consecutive points of each storm
  SELECT
    sid,
    ST_DISTANCE(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(
        LAG(longitude) OVER (PARTITION BY sid ORDER BY iso_time),
        LAG(latitude)  OVER (PARTITION BY sid ORDER BY iso_time)
      )
    ) AS segment_m
  FROM atl_2020
),
storm_totals AS (
  -- total traveled distance per storm
  SELECT
    sid,
    SUM(segment_m) AS total_m
  FROM path_dist
  WHERE segment_m IS NOT NULL        -- first point has NULL distance
  GROUP BY sid
),
second_longest AS (
  -- storm that traveled the 2nd‑longest distance
  SELECT sid
  FROM (
    SELECT
      sid,
      total_m,
      DENSE_RANK() OVER (ORDER BY total_m DESC) AS rk
    FROM storm_totals
  )
  WHERE rk = 2
),
final_position AS (
  -- final (last) coordinate of that storm
  SELECT
    a.sid,
    a.latitude,
    ROW_NUMBER() OVER (PARTITION BY a.sid ORDER BY a.iso_time DESC) AS rn
  FROM atl_2020 AS a
  JOIN second_longest USING (sid)
)
SELECT
  latitude
FROM final_position
WHERE rn = 1;
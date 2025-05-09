WITH na2020 AS (                                            -- 2020 North-Atlantic positions
  SELECT sid, iso_time, latitude, longitude
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE season = '2020' AND basin = 'NA'
),
segments AS (                                               -- successive-fix distances
  SELECT
    sid,
    IFNULL(
      ST_DISTANCE(
        ST_GEOGPOINT(LAG(longitude) OVER w, LAG(latitude) OVER w),
        ST_GEOGPOINT(longitude, latitude)
      ), 0) AS segment_m
  FROM na2020
  WINDOW w AS (PARTITION BY sid ORDER BY iso_time)
),
ranked AS (                                                 -- rank storms by total path length
  SELECT
    sid,
    ROW_NUMBER() OVER (ORDER BY SUM(segment_m) DESC) AS rn
  FROM segments
  GROUP BY sid
),
second_sid AS (                                             -- second-longest-travelled storm
  SELECT sid FROM ranked WHERE rn = 2
)
SELECT latitude AS final_latitude                           -- latitude of its final fix
FROM na2020
WHERE sid IN (SELECT sid FROM second_sid)
QUALIFY iso_time = MAX(iso_time) OVER (PARTITION BY sid);
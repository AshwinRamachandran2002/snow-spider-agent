WITH atl_2020 AS (
  -- 2020 Atlantic track points with valid coordinates
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
    AND basin  = 'NA'          -- North Atlantic basin
    AND latitude  IS NOT NULL
    AND longitude IS NOT NULL
),
seg_dist AS (
  -- distance between consecutive fixes for each storm
  SELECT
    sid,
    iso_time,
    latitude,
    longitude,
    ST_DISTANCE(
      geom,
      LAG(geom) OVER (PARTITION BY sid ORDER BY iso_time)
    ) AS leg_m
  FROM atl_2020
),
storm_totals AS (
  -- total travelled distance for every storm
  SELECT
    sid,
    SUM(IFNULL(leg_m,0)) AS track_len_m
  FROM seg_dist
  GROUP BY sid
),
second_longest_sid AS (
  -- identify the storm with the second‑longest track
  SELECT sid
  FROM (
    SELECT
      sid,
      track_len_m,
      ROW_NUMBER() OVER (ORDER BY track_len_m DESC) AS rn
    FROM storm_totals
  )
  WHERE rn = 2
),
final_fix AS (
  -- get the last reported position for that storm
  SELECT
    a.sid,
    a.latitude AS final_latitude,
    ROW_NUMBER() OVER (PARTITION BY a.sid ORDER BY a.iso_time DESC) AS rn
  FROM atl_2020 a
  JOIN second_longest_sid s USING (sid)
)
SELECT
  final_latitude
FROM final_fix
WHERE rn = 1;
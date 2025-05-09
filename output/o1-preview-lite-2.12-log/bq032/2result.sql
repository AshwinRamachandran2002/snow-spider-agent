WITH total_distances AS (
  SELECT `sid`, SUM(segment_distance_meters) AS total_distance_meters
  FROM (
    SELECT `sid`,
      ST_DISTANCE(
        ST_GEOGPOINT(`longitude`, `latitude`),
        ST_GEOGPOINT(
          LEAD(`longitude`) OVER (PARTITION BY `sid` ORDER BY `iso_time`),
          LEAD(`latitude`) OVER (PARTITION BY `sid` ORDER BY `iso_time`)
        )
      ) AS segment_distance_meters
    FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
    WHERE `season` = '2020' AND `basin` = 'NA'
  )
  GROUP BY `sid`
),
ranked_hurricanes AS (
  SELECT `sid`, total_distance_meters,
    ROW_NUMBER() OVER (ORDER BY total_distance_meters DESC) AS rn
  FROM total_distances
),
latest_positions AS (
  SELECT `sid`, `latitude`
  FROM (
    SELECT `sid`, `latitude`, `iso_time`,
      ROW_NUMBER() OVER (PARTITION BY `sid` ORDER BY `iso_time` DESC) AS rn
    FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
    WHERE `season` = '2020' AND `basin` = 'NA'
  )
  WHERE rn = 1
)
SELECT ROUND(latest_positions.latitude, 4) AS latitude
FROM ranked_hurricanes
JOIN latest_positions ON ranked_hurricanes.sid = latest_positions.sid
WHERE ranked_hurricanes.rn = 2
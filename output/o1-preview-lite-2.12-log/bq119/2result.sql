SELECT
  CONCAT('POINT(',
    CAST(ROUND(`longitude`, 4) AS STRING),
    ' ',
    CAST(ROUND(`latitude`, 4) AS STRING),
    ')') AS geom,
  ROUND(SUM(IFNULL(`segment_distance`, 0)) OVER (ORDER BY `iso_time`), 4) AS cumulative_distance_meters,
  `wmo_wind`
FROM (
  SELECT
    `iso_time`,
    `latitude`,
    `longitude`,
    `wmo_wind`,
    ST_DISTANCE(
      ST_GEOGPOINT(`longitude`, `latitude`),
      ST_GEOGPOINT(
        LAG(`longitude`) OVER (ORDER BY `iso_time`),
        LAG(`latitude`) OVER (ORDER BY `iso_time`)
      )
    ) AS `segment_distance`
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE `sid` = (
    SELECT `sid` FROM (
      SELECT `sid`, SUM(`segment_distance`) AS total_distance_meters
      FROM (
        SELECT `sid`,
          ST_DISTANCE(
            ST_GEOGPOINT(`longitude`, `latitude`),
            ST_GEOGPOINT(
              LAG(`longitude`) OVER (PARTITION BY `sid` ORDER BY `iso_time`),
              LAG(`latitude`) OVER (PARTITION BY `sid` ORDER BY `iso_time`)
            )
          ) AS `segment_distance`
        FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
        WHERE `season` = '2020' AND `basin` = 'NA' AND `latitude` IS NOT NULL AND `longitude` IS NOT NULL
      ) AS distances
      WHERE `segment_distance` IS NOT NULL
      GROUP BY `sid`
      ORDER BY total_distance_meters DESC
      LIMIT 1 OFFSET 2
    )
  ) AND `latitude` IS NOT NULL AND `longitude` IS NOT NULL
)
ORDER BY `iso_time`;
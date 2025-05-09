-- Highest average speed (m/s, rounded to 1 decimal) for Berkeley bike-share trips
SELECT
  ROUND(
    MAX(
      ST_DISTANCE(start_station_geom, end_station_geom)
/ NULLIF(duration_sec, 0)
    ),
    1
  ) AS highest_avg_speed_mps
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
WHERE
  ST_DISTANCE(start_station_geom, end_station_geom) > 1000                    -- trip > 1 km
  AND (
        CAST(start_station_id AS STRING) IN (
          SELECT station_id
          FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`
          WHERE region_id = 14                                                -- Berkeley region
        )
     OR CAST(end_station_id   AS STRING) IN (
          SELECT station_id
          FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info`
          WHERE region_id = 14
        )
  );
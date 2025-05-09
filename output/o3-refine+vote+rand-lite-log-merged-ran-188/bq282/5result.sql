WITH station_district AS (
  SELECT
    CAST(station_id AS INT64) AS station_id,
    council_district
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE council_district IS NOT NULL
),

trips_with_districts AS (
  SELECT
    t.trip_id,
    t.start_station_id,
    SAFE_CAST(t.end_station_id AS INT64) AS end_station_id_int,
    s_start.council_district AS start_district,
    s_end.council_district   AS end_district
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips` t
  JOIN station_district s_start
    ON t.start_station_id = s_start.station_id
  JOIN station_district s_end
    ON SAFE_CAST(t.end_station_id AS INT64) = s_end.station_id
  WHERE SAFE_CAST(t.end_station_id AS INT64) IS NOT NULL
),

trips_same_district AS (
  SELECT
    start_district AS council_district
  FROM trips_with_districts
  WHERE
    start_district = end_district          -- same council district
    AND start_station_id <> end_station_id_int  -- but different stations
)

SELECT
  council_district
FROM
  trips_same_district
GROUP BY
  council_district
ORDER BY
  COUNT(*) DESC
LIMIT 1;
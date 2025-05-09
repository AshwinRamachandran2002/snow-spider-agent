-- Highest‑volume active council district for same‑district / different‑station trips
WITH active_stations AS (
  SELECT station_id, council_district
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_stations`
  WHERE LOWER(status) IN ('active','open')
)
SELECT council_district
FROM (
  SELECT
    s1.council_district,
    COUNT(*) AS trip_cnt,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips` AS t
  JOIN active_stations AS s1
    ON t.start_station_id = s1.station_id
  JOIN active_stations AS s2
    ON SAFE_CAST(t.end_station_id AS INT64) = s2.station_id
  WHERE s1.council_district = s2.council_district
    AND t.start_station_id <> SAFE_CAST(t.end_station_id AS INT64)
  GROUP BY s1.council_district
)
WHERE rnk = 1
LIMIT 1;
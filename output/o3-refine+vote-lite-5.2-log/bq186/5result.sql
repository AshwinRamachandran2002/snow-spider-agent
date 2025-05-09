WITH sf_stations AS (
  SELECT
    station_id
  FROM
    `bigquery-public-data.san_francisco.bikeshare_stations`
  WHERE
    landmark = 'San Francisco'            -- keep only SF stations
),
sf_trips AS (
  SELECT
    FORMAT_TIMESTAMP('%Y%m', start_date)              AS year_month,      -- YYYYMM key
    duration_sec / 60.0                               AS duration_minutes,
    start_date
  FROM
    `bigquery-public-data.san_francisco.bikeshare_trips` t
  JOIN
    sf_stations s
  ON
    t.start_station_id = s.station_id                 -- retain trips that start in SF
)
SELECT
  year_month,
  -- first trip (earliest start_date within the month)
  ARRAY_AGG(duration_minutes ORDER BY start_date ASC  LIMIT 1)[OFFSET(0)]  AS first_trip_minutes,
  -- last trip (latest start_date within the month)
  ARRAY_AGG(duration_minutes ORDER BY start_date DESC LIMIT 1)[OFFSET(0)]  AS last_trip_minutes,
  MAX(duration_minutes) AS highest_trip_minutes,
  MIN(duration_minutes) AS lowest_trip_minutes
FROM
  sf_trips
GROUP BY
  year_month
ORDER BY
  year_month;
WITH
  durations AS (
    SELECT
      FORMAT_DATE('%Y-%m', DATE(start_date)) AS Month,
      MAX(duration_sec) / 60 AS Highest_duration_minutes,
      MIN(duration_sec) / 60 AS Lowest_duration_minutes
    FROM
      `bigquery-public-data.san_francisco.bikeshare_trips`
    GROUP BY
      Month
  ),
  numbered_trips AS (
    SELECT
      FORMAT_DATE('%Y-%m', DATE(start_date)) AS Month,
      duration_sec / 60 AS duration_minutes,
      ROW_NUMBER() OVER (
        PARTITION BY FORMAT_DATE('%Y-%m', DATE(start_date))
        ORDER BY start_date ASC
      ) AS rn_first,
      ROW_NUMBER() OVER (
        PARTITION BY FORMAT_DATE('%Y-%m', DATE(start_date))
        ORDER BY start_date DESC
      ) AS rn_last
    FROM
      `bigquery-public-data.san_francisco.bikeshare_trips`
  ),
  first_trips AS (
    SELECT
      Month,
      duration_minutes AS First_trip_duration_minutes
    FROM
      numbered_trips
    WHERE
      rn_first = 1
  ),
  last_trips AS (
    SELECT
      Month,
      duration_minutes AS Last_trip_duration_minutes
    FROM
      numbered_trips
    WHERE
      rn_last = 1
  )
SELECT
  durations.Month,
  first_trips.First_trip_duration_minutes,
  last_trips.Last_trip_duration_minutes,
  durations.Highest_duration_minutes,
  durations.Lowest_duration_minutes
FROM
  durations
  JOIN first_trips USING (Month)
  JOIN last_trips USING (Month)
ORDER BY
  durations.Month;
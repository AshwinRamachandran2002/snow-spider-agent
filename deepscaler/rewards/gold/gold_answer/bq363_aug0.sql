-- Task: Calculate the total number of taxi trips and the average fare (formatted to two decimal places) for ten equal quantile groups of trips with durations rounded to the nearest minute between 1 and 50 minutes. The quantile groups are formed by ordering the trips by rounded duration and dividing them into ten equal parts using NTILE(10). For each quantile group, display the formatted time range in minutes (e.g., '01m to 05m'), representing the minimum and maximum durations within that group. Sort the results chronologically by the time range.

SELECT
  FORMAT('%02.0fm to %02.0fm', min_minutes, max_minutes) AS minutes_range,
  SUM(trips) AS total_trips,
  FORMAT('%3.2f', SUM(total_fare) / SUM(trips)) AS average_fare
FROM (
  SELECT
    MIN(duration_in_minutes) OVER (quantiles) AS min_minutes,
    MAX(duration_in_minutes) OVER (quantiles) AS max_minutes,
    SUM(trips) AS trips,
    SUM(total_fare) AS total_fare
  FROM (
    SELECT
      ROUND(trip_seconds / 60) AS duration_in_minutes,
      NTILE(10) OVER (ORDER BY trip_seconds / 60) AS quantile,
      COUNT(1) AS trips,
      SUM(fare) AS total_fare
    FROM
      `bigquery-public-data.chicago_taxi_trips.taxi_trips`
    WHERE
      ROUND(trip_seconds / 60) BETWEEN 1 AND 50
    GROUP BY
      trip_seconds,
      duration_in_minutes )
  GROUP BY
    duration_in_minutes,
    quantile
  WINDOW quantiles AS (PARTITION BY quantile)
  )
GROUP BY
  minutes_range
ORDER BY
  minutes_range;
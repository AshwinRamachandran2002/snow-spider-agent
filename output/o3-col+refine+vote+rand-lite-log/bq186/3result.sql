WITH w AS (
  SELECT
    FORMAT_TIMESTAMP('%Y%m', start_date)                              AS year_month,
    ROUND(duration_sec / 60.0, 4)                                     AS duration_min,

    -- first trip (earliest start_date) in the month
    FIRST_VALUE(ROUND(duration_sec / 60.0, 4)) OVER (
      PARTITION BY FORMAT_TIMESTAMP('%Y%m', start_date)
      ORDER BY start_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS first_duration_min,

    -- last trip (latest start_date) in the month
    LAST_VALUE(ROUND(duration_sec / 60.0, 4)) OVER (
      PARTITION BY FORMAT_TIMESTAMP('%Y%m', start_date)
      ORDER BY start_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_duration_min,

    -- lowest & highest trip durations in the month
    MIN(ROUND(duration_sec / 60.0, 4)) OVER (
      PARTITION BY FORMAT_TIMESTAMP('%Y%m', start_date)
    ) AS lowest_duration_min,
    MAX(ROUND(duration_sec / 60.0, 4)) OVER (
      PARTITION BY FORMAT_TIMESTAMP('%Y%m', start_date)
    ) AS highest_duration_min
  FROM `bigquery-public-data.san_francisco.bikeshare_trips`
)

SELECT DISTINCT
  year_month,
  first_duration_min,
  last_duration_min,
  highest_duration_min,
  lowest_duration_min
FROM w
ORDER BY year_month;
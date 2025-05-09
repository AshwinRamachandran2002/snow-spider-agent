WITH daily_counts AS (
  SELECT
    year,
    month,
    day,
    COUNT(*) AS sightings
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE species = 'Sterna paradisaea'
    AND decimallatitude > 40     -- north of 40° latitude
    AND month > 1                -- after January
    AND month IS NOT NULL
    AND day IS NOT NULL
  GROUP BY year, month, day
  HAVING COUNT(*) > 10           -- more than 10 sightings
),
first_day_per_year AS (
  SELECT
    year,
    MIN(DATE(year, month, day)) AS first_day_over10_sightings
  FROM daily_counts
  GROUP BY year
)
SELECT
  CAST(year AS INT64) AS year,
  FORMAT_DATE('%Y-%m-%d', first_day_over10_sightings) AS first_day_over10_sightings
FROM first_day_per_year
ORDER BY first_day_over10_sightings
LIMIT 1;
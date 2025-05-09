WITH daily_counts AS (
  -- Daily records (>10) of Sterna paradisaea north of 40 °N after January
  SELECT
    year,
    DATE(eventdate) AS obs_date,
    COUNT(*) AS records
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE species = 'Sterna paradisaea'
    AND decimallatitude > 40
    AND month > 1           -- after January
  GROUP BY year, obs_date
  HAVING COUNT(*) > 10
),
first_day_per_year AS (
  -- First day (>10 records) for each year
  SELECT
    year,
    MIN(obs_date) AS first_day_gt10
  FROM daily_counts
  GROUP BY year
)
-- Year whose first qualifying day is the earliest overall
SELECT year
FROM first_day_per_year
ORDER BY first_day_gt10
LIMIT 1;
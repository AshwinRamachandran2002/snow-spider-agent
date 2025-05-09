-- Earliest post-January date (north of 40 °N) with >10 sightings and the year it occurred
WITH daily_counts AS (
  SELECT
    year,
    month,
    day,
    COUNT(*) AS sightings
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE species = 'Sterna paradisaea'
    AND decimallatitude > 40          -- north of 40° N
    AND month > 1                     -- exclude January
    AND day IS NOT NULL               -- need valid day
  GROUP BY year, month, day
  HAVING COUNT(*) > 10                -- more than 10 sightings
),
first_per_year AS (
  SELECT
    year,
    MIN(DATE(year, month, day)) AS first_big_day
  FROM daily_counts
  GROUP BY year
)
SELECT
  year,
  first_big_day
FROM first_per_year
ORDER BY first_big_day
LIMIT 1;
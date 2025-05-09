WITH daily_counts AS (
  SELECT
    year,
    DATE(year, month, day) AS obs_date,
    COUNT(*) AS sighting_count
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE LOWER(species) = 'sterna paradisaea'      -- Arctic Tern
    AND decimallatitude > 40                      -- north of 40° N
    AND month > 1                                 -- after January
    AND year  IS NOT NULL
    AND month IS NOT NULL
    AND day   IS NOT NULL
  GROUP BY year, month, day
  HAVING COUNT(*) > 10                            -- more than 10 sightings that day
),
first_day_per_year AS (
  SELECT
    year,
    MIN(obs_date) AS first_day_over10_sightings
  FROM daily_counts
  GROUP BY year
)
SELECT
  year,
  first_day_over10_sightings
FROM first_day_per_year
ORDER BY first_day_over10_sightings
LIMIT 1;
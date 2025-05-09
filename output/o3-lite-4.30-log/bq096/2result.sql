WITH daily AS (
  SELECT
    EXTRACT(YEAR  FROM eventdate)        AS yr,
    DATE(eventdate)                      AS obs_date,
    COUNT(*)                             AS n_obs
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE LOWER(species) = 'sterna paradisaea'
    AND decimallatitude > 40
    AND month > 1                          -- exclude January
  GROUP BY yr, obs_date
  HAVING n_obs > 10                        -- >10 sightings on that day
),
first_per_year AS (
  SELECT
    yr AS year,
    MIN(obs_date) AS first_day_over10_sightings
  FROM daily
  GROUP BY year
),
earliest AS (
  SELECT *
  FROM first_per_year
  ORDER BY EXTRACT(DAYOFYEAR FROM first_day_over10_sightings), year
  LIMIT 1
)
SELECT
  year,
  first_day_over10_sightings
FROM earliest;
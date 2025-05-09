WITH filtered AS (
  SELECT
    `year`,
    DATE(`year`, `month`, `day`) AS obs_date
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE
    species = 'Sterna paradisaea'    -- species of interest
    AND decimallatitude > 40         -- north of 40° N
    AND `year` IS NOT NULL
    AND `month` IS NOT NULL
    AND `day` IS NOT NULL
    AND `month` > 1                  -- after January
),
daily_counts AS (
  SELECT
    `year`,
    obs_date,
    COUNT(*) AS sightings
  FROM filtered
  GROUP BY `year`, obs_date
),
first_dates AS (
  SELECT
    `year`,
    MIN(obs_date) AS first_sufficient_date
  FROM daily_counts
  WHERE sightings > 10               -- > 10 sightings on the day
  GROUP BY `year`
)
SELECT
  `year`,
  first_sufficient_date
FROM first_dates
ORDER BY first_sufficient_date, `year`
LIMIT 1;
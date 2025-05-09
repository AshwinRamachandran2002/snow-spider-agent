WITH daily_counts AS (
  -- Number of sightings per day north of 40° lat after January
  SELECT
    `year`,
    DATE(`eventdate`) AS obs_date,
    COUNT(*)          AS sightings
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE
      `species`            = 'Sterna paradisaea'
  AND `decimallatitude`    > 40
  AND `month`              > 1               -- after January
  AND `eventdate`          IS NOT NULL
  GROUP BY `year`, obs_date
),
first_day_over_10 AS (
  -- For every year keep the first day with >10 sightings
  SELECT
    `year`,
    MIN(obs_date) AS first_over_10_date
  FROM  daily_counts
  WHERE sightings > 10
  GROUP BY `year`
),
earliest_year AS (
  -- Pick the year whose first_over_10_date is the earliest overall
  SELECT
    *
  FROM  first_day_over_10
  ORDER BY first_over_10_date, `year`
  LIMIT 1
)
SELECT
  `year`,
  first_over_10_date
FROM earliest_year;
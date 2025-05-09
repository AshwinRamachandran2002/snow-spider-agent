WITH filtered AS (
  -- All sightings of Sterna paradisaea north of 40 °N, after January
  SELECT
    DATE(eventdate)                       AS obs_date,
    EXTRACT(YEAR  FROM eventdate)         AS yr
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE
        LOWER(species) = 'sterna paradisaea'     -- the target species
    AND decimallatitude > 40                     -- north of 40 ° latitude
    AND eventdate IS NOT NULL
    AND EXTRACT(MONTH FROM eventdate) > 1        -- after January
),
daily_counts AS (
  -- How many sightings occurred on each day of each year
  SELECT
    yr,
    obs_date,
    COUNT(*) AS sightings
  FROM filtered
  GROUP BY yr, obs_date
  HAVING sightings > 10                          -- keep only days with > 10 sightings
),
earliest_per_year AS (
  -- For every year, keep the first qualifying day
  SELECT
    yr,
    obs_date,
    ROW_NUMBER() OVER (PARTITION BY yr ORDER BY obs_date) AS rn
  FROM daily_counts
)
-- Pick the year whose first qualifying day is the earliest in the calendar
SELECT
  yr   AS year_with_earliest_date,
  obs_date AS first_date_with_over_10_sightings
FROM (
  SELECT
    yr,
    obs_date,
    EXTRACT(DAYOFYEAR FROM obs_date) AS doy
  FROM earliest_per_year
  WHERE rn = 1                          -- earliest in its year
)
ORDER BY doy, yr                        -- earliest day‑of‑year wins; tie‑break by year
LIMIT 1;
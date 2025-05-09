-- Earliest “rich” (>10 sightings) day after January for Sterna paradisaea north of 40 °N,
-- and the year in which it occurs
WITH rich_days AS (
  -- 1. All observation days that satisfy the geographic / temporal filters
  SELECT
    DATE(eventdate)                  AS obs_date,
    EXTRACT(YEAR FROM eventdate)     AS yr
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE LOWER(species) = 'sterna paradisaea'   -- species match (case‑insensitive)
    AND decimallatitude > 40                  -- north of 40 °N
    AND month > 1                             -- after January
  GROUP BY yr, obs_date
  HAVING COUNT(*) > 10                        -- keep only “rich” days (>10 sightings)
),
first_rich_day_per_year AS (                  -- 2. Earliest rich day for every year
  SELECT
    yr,
    MIN(obs_date) AS first_rich_day
  FROM rich_days
  GROUP BY yr
)
-- 3. Year whose first rich day is earliest overall
SELECT
  yr  AS year_with_earliest_rich_day,
  first_rich_day
FROM first_rich_day_per_year
ORDER BY first_rich_day
LIMIT 1;
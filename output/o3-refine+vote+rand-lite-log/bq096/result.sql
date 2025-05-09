-- Year whose first post‑January day with >10 north‑of‑40° sightings of
-- Sterna paradisaea is earliest among all years
WITH filtered AS (
  SELECT
    `year`,
    `month`,
    `day`
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE
    species = 'Sterna paradisaea'        -- target species
    AND decimallatitude > 40             -- north of 40°
    AND `year` IS NOT NULL               -- keep complete dates
    AND `month` IS NOT NULL
    AND `day` IS NOT NULL
),
daily_counts AS (
  SELECT
    `year`,
    `month`,
    `day`,
    COUNT(*) AS cnt
  FROM filtered
  GROUP BY `year`, `month`, `day`
  HAVING cnt > 10        -- more than 10 sightings that day
     AND `month` > 1     -- after January
),
first_day_per_year AS (
  SELECT
    `year`,
    DATE(`year`, `month`, `day`) AS first_day
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY `year`
                         ORDER BY `month`, `day`) AS rn
    FROM daily_counts
  )
  WHERE rn = 1           -- earliest qualifying day for each year
),
earliest_year AS (
  SELECT
    `year`,
    ROW_NUMBER() OVER (ORDER BY first_day, `year`) AS rn
  FROM first_day_per_year
)
SELECT `year`
FROM earliest_year
WHERE rn = 1;
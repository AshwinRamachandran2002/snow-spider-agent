-- Find the year whose first (earliest) post‑January day
-- with more than 10 north‑of‑40° records of Sterna paradisaea
-- is earliest among all years
WITH daily_counts AS (
  SELECT
    `year`,
    `month`,
    `day`,
    COUNT(*) AS sightings
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE
    species = 'Sterna paradisaea'          -- target species
    AND decimallatitude > 40              -- north of 40° N
    AND `month` >= 2                      -- “after January”
    AND `year`  IS NOT NULL
    AND `month` IS NOT NULL
    AND `day`   IS NOT NULL
  GROUP BY `year`, `month`, `day`
  HAVING sightings > 10                   -- more than 10 sightings
),
earliest_per_year AS (
  SELECT
    `year`,
    MIN(DATE(`year`, `month`, `day`)) AS first_big_day
  FROM daily_counts
  GROUP BY `year`
)
SELECT
  `year`,
  first_big_day
FROM earliest_per_year
ORDER BY first_big_day, `year`            -- earliest date wins; tie‑break by year
LIMIT 1;
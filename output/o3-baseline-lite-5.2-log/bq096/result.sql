-- 1.  Filter records for Sterna paradisaea seen north of 40 ° N, after January,
--     keeping only rows that have day & month.
-- 2.  Aggregate to counts per calendar day (year‑month‑day).
-- 3.  Keep the days where > 10 sightings occurred.
-- 4.  For each year, pick that year’s earliest such day (after January).
-- 5.  Compare those “first days” across years; the year whose first day is
--     earliest (smallest day‑of‑year) is returned.

WITH filtered AS (
  SELECT
    `year`,
    `month`,
    `day`
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE species = 'Sterna paradisaea'       -- the target species
    AND decimallatitude > 40                -- north of 40° N
    AND month IS NOT NULL
    AND day   IS NOT NULL
    AND month > 1                           -- after January
),
daily_counts AS (
  SELECT
    `year`,
    `month`,
    `day`,
    COUNT(*) AS sighting_cnt
  FROM filtered
  GROUP BY `year`, `month`, `day`
  HAVING sighting_cnt > 10                  -- only days with > 10 sightings
),
first_day_per_year AS (
  SELECT
    `year`,
    ARRAY_AGG(
      STRUCT(`month`, `day`)
      ORDER BY EXTRACT(DAYOFYEAR FROM DATE(`year`, `month`, `day`))
      LIMIT 1
    )[OFFSET(0)] AS first_md,
    MIN(EXTRACT(DAYOFYEAR FROM DATE(`year`, `month`, `day`))) AS first_doy
  FROM daily_counts
  GROUP BY `year`
),
ranked AS (
  SELECT
    `year`,
    first_md.month AS first_month,
    first_md.day   AS first_day,
    first_doy,
    RANK() OVER (ORDER BY first_doy ASC, `year` ASC) AS rnk
  FROM first_day_per_year
)
SELECT `year`
FROM ranked
WHERE rnk = 1;
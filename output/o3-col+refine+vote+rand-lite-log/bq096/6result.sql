-- Earliest post-January date with >10 sightings of Sterna paradisaea north of 40 °N
WITH daily_counts AS (
  SELECT
    year,
    DATE(eventdate) AS cal_date,
    COUNT(*) AS n_sightings
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE LOWER(scientificname) LIKE 'sterna paradisaea%'
    AND decimallatitude > 40
  GROUP BY year, cal_date
  HAVING n_sightings > 10               -- more than 10 sightings that day
     AND EXTRACT(MONTH FROM cal_date) > 1  -- after January
),
first_big_day_per_year AS (
  SELECT
    year,
    MIN(cal_date) AS first_big_day
  FROM daily_counts
  GROUP BY year
)
SELECT
  first_big_day,
  year
FROM first_big_day_per_year
ORDER BY first_big_day
LIMIT 1;
-- Year with the earliest post-January day that recorded >10 Arctic Tern sightings
WITH daily_counts AS (
  SELECT
    DATE(`eventdate`)              AS obs_date,
    EXTRACT(YEAR FROM `eventdate`) AS yr,
    COUNT(*)                       AS cnt
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE LOWER(`species`)  = 'sterna paradisaea'      -- Arctic Tern
    AND `decimallatitude` > 40                       -- north of 40° N
    AND `month`           > 1                        -- after January
  GROUP BY obs_date, yr
  HAVING cnt > 10                                    -- more than 10 sightings
),
first_big_day_per_year AS (
  SELECT
    yr,
    MIN(obs_date) AS first_big_day
  FROM daily_counts
  GROUP BY yr
)
SELECT yr
FROM first_big_day_per_year
ORDER BY first_big_day
LIMIT 1;
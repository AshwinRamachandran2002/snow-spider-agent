WITH daily_counts AS (
  SELECT
    DATE(`eventdate`)                      AS obs_date,
    EXTRACT(YEAR FROM `eventdate`)        AS yr,
    COUNT(1)                              AS n_sightings
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE
        `species`         = 'Sterna paradisaea'
    AND `decimallatitude` > 40
    AND `eventdate`       IS NOT NULL
    AND EXTRACT(MONTH FROM `eventdate`) > 1      -- after January
  GROUP BY obs_date, yr
),
first_big_day_per_year AS (
  SELECT
    yr,
    MIN(obs_date) AS first_big_day
  FROM daily_counts
  WHERE n_sightings > 10                   -- days with >10 sightings
  GROUP BY yr
)
SELECT
  yr  AS year_with_earliest_date,
  first_big_day AS earliest_date
FROM first_big_day_per_year
ORDER BY earliest_date
LIMIT 1;
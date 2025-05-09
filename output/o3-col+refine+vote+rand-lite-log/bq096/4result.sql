WITH crowded_days AS (
  SELECT
    DATE(`eventdate`) AS obs_date
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE LOWER(`scientificname`) LIKE 'sterna paradisaea%'   -- species (allow author suffix)
    AND `decimallatitude` > 40                              -- north of 40 °N
    AND EXTRACT(MONTH FROM `eventdate`) > 1                 -- exclude January
  GROUP BY obs_date
  HAVING COUNT(*) > 10                                      -- “crowded” day
),
first_day_per_year AS (
  SELECT
    EXTRACT(YEAR FROM obs_date) AS yr,
    MIN(obs_date)              AS first_crowded_day
  FROM crowded_days
  GROUP BY yr
)
SELECT yr
FROM   first_day_per_year
ORDER  BY first_crowded_day
LIMIT 1;
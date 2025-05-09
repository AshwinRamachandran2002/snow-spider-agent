-- Which year had the earliest (> Jan) day with more than 10 sightings
-- of Sterna paradisaea north of 40° latitude?
WITH daily AS (
  SELECT
    EXTRACT(YEAR FROM `eventdate`) AS yr,
    DATE(`eventdate`)             AS obs_date,
    COUNT(*)                      AS n_obs
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE LOWER(`scientificname`) LIKE '%sterna paradisaea%'
    AND `decimallatitude` > 40
    AND EXTRACT(MONTH FROM `eventdate`) > 1          -- after January
  GROUP BY yr, obs_date
  HAVING n_obs > 10                                   -- >10 sightings that day
),
first_per_year AS (
  SELECT
    yr,
    MIN(obs_date) AS first_big_sighting_date          -- first qualifying day each year
  FROM daily
  GROUP BY yr
)
SELECT
  yr,
  first_big_sighting_date
FROM first_per_year
ORDER BY first_big_sighting_date                       -- earliest of all years
LIMIT 1;
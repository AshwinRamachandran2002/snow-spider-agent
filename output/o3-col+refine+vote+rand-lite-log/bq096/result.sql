-- Earliest year whose first >10-records day (after January, north of 40 °N)
-- for Arctic Tern (Sterna paradisaea) is earliest among all years
WITH daily AS (
  SELECT
    DATE(eventdate)                       AS sighting_date,
    EXTRACT(YEAR  FROM eventdate)         AS yr,
    COUNT(*)                              AS n_records
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE species              = 'Sterna paradisaea'
    AND decimallatitude      > 40
    AND EXTRACT(MONTH FROM eventdate) > 1     -- after January
  GROUP BY sighting_date, yr
),
qualified AS (            -- keep only days with >10 sightings
  SELECT *
  FROM daily
  WHERE n_records > 10
),
earliest_per_year AS (    -- first such day per year
  SELECT
    yr,
    MIN(sighting_date) AS first_big_day
  FROM qualified
  GROUP BY yr
)
SELECT                     -- year with the overall earliest big day
  yr  AS year_with_earliest_big_day,
  first_big_day
FROM earliest_per_year
ORDER BY first_big_day
LIMIT 1;
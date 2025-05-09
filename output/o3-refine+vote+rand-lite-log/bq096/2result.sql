WITH species_daily AS (
  SELECT
    DATE(eventdate)                                          AS observation_date,
    EXTRACT(YEAR  FROM eventdate)                            AS yr,
    COUNT(*)                                                 AS cnt
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE species              = 'Sterna paradisaea'      -- the species of interest
    AND decimallatitude      > 40                      -- north of 40° latitude
    AND eventdate            IS NOT NULL
    AND EXTRACT(MONTH FROM eventdate) > 1              -- after January
  GROUP BY observation_date, yr
),
year_first_date AS (        -- first date in each year with >10 sightings
  SELECT
    yr,
    MIN(observation_date) AS first_date
  FROM species_daily
  WHERE cnt > 10
  GROUP BY yr
),
ranked AS (                 -- rank by day‑of‑year, tie‑break by year
  SELECT
    yr,
    first_date,
    ROW_NUMBER() OVER (
      ORDER BY EXTRACT(DAYOFYEAR FROM first_date), yr
    ) AS rn
  FROM year_first_date
)
SELECT
  yr  AS year_with_earliest_threshold_date,
  first_date
FROM ranked
WHERE rn = 1;
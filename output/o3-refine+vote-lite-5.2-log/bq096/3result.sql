WITH filtered AS (
  SELECT
    `year`,
    DATE(`eventdate`) AS obs_date
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE
        -- species of interest
        `species` = 'Sterna paradisaea'
    -- north of 40° N
    AND `decimallatitude` > 40
    -- we need a valid date
    AND `eventdate` IS NOT NULL
    -- only days **after** January
    AND EXTRACT(MONTH FROM DATE(`eventdate`)) > 1
),
daily_counts AS (
  SELECT
    `year`,
    obs_date,
    COUNT(*) AS sightings
  FROM filtered
  GROUP BY `year`, obs_date
  HAVING sightings > 10          -- more than 10 sightings that day
),
first_per_year AS (
  SELECT
    `year`,
    MIN(obs_date) AS first_date  -- first qualifying day in that year
  FROM daily_counts
  GROUP BY `year`
),
earliest_year AS (
  SELECT
    `year`,
    first_date,
    ROW_NUMBER() OVER (ORDER BY EXTRACT(DAYOFYEAR FROM first_date), `year`) AS rn
  FROM first_per_year
)
SELECT
  `year`,
  first_date
FROM earliest_year
WHERE rn = 1;        -- the year whose first qualifying day is earliest of all
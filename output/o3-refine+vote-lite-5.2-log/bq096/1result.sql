WITH filtered AS (
  -- keep only Arctic‑tern records north of 40° and build a reliable DATE
  SELECT
    COALESCE(                       -- prefer the supplied timestamp
      DATE(eventdate),
      SAFE.PARSE_DATE(              -- otherwise compose a date from Y‑M‑D
        '%Y-%m-%d',
        CONCAT(
          CAST(year  AS STRING),'-',
          LPAD(CAST(month AS STRING),2,'0'),'-',
          LPAD(CAST(day   AS STRING),2,'0')
        )
      )
    ) AS event_date
  FROM `bigquery-public-data.gbif.occurrences`
  WHERE species = 'Sterna paradisaea'      -- Arctic Tern
    AND decimallatitude > 40               -- north of 40°
),
daily_counts AS (
  -- count sightings per day after January
  SELECT
    event_date,
    EXTRACT(YEAR  FROM event_date) AS yr,
    COUNT(*)                       AS cnt
  FROM filtered
  WHERE event_date IS NOT NULL
    AND EXTRACT(MONTH FROM event_date) > 1 -- after January
  GROUP BY event_date
  HAVING cnt > 10                          -- more than 10 sightings
),
earliest_per_year AS (
  -- first qualifying day for each year
  SELECT
    yr,
    MIN(event_date) AS first_date
  FROM daily_counts
  GROUP BY yr
)
-- pick the year whose first qualifying day is the earliest overall
SELECT
  yr   AS year,
  first_date
FROM earliest_per_year
ORDER BY first_date, yr
LIMIT 1;
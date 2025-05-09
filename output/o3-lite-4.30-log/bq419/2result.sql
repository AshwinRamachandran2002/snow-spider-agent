WITH all_events AS (
  SELECT 1980 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1980` WHERE state IS NOT NULL
  UNION ALL
  SELECT 1981 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1981` WHERE state IS NOT NULL
  UNION ALL
  SELECT 1982 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1982` WHERE state IS NOT NULL
  UNION ALL
  SELECT 1983 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1983` WHERE state IS NOT NULL
  UNION ALL
  SELECT 1984 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1984` WHERE state IS NOT NULL
  UNION ALL
  SELECT 1985 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1985` WHERE state IS NOT NULL
  UNION ALL
  SELECT 1986 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1986` WHERE state IS NOT NULL
  UNION ALL
  SELECT 1987 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1987` WHERE state IS NOT NULL
  UNION ALL
  SELECT 1988 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1988` WHERE state IS NOT NULL
  UNION ALL
  SELECT 1989 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1989` WHERE state IS NOT NULL
  UNION ALL
  SELECT 1990 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1990` WHERE state IS NOT NULL
  UNION ALL
  SELECT 1991 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1991` WHERE state IS NOT NULL
  UNION ALL
  SELECT 1992 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1992` WHERE state IS NOT NULL
  UNION ALL
  SELECT 1993 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1993` WHERE state IS NOT NULL
  UNION ALL
  SELECT 1994 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1994` WHERE state IS NOT NULL
  UNION ALL
  SELECT 1995 AS yr, UPPER(state) AS state FROM `bigquery-public-data.noaa_historic_severe_storms.storms_1995` WHERE state IS NOT NULL
),
yearly_counts AS (
  SELECT yr, state, COUNT(*) AS events
  FROM all_events
  GROUP BY yr, state
),
ranked AS (
  SELECT
    yr,
    state,
    events,
    ROW_NUMBER() OVER (PARTITION BY yr ORDER BY events DESC) AS rn
  FROM yearly_counts
),
top1000 AS (
  SELECT state, events
  FROM ranked
  WHERE rn <= 1000
)
SELECT
  state,
  SUM(events) AS total_storm_events
FROM top1000
GROUP BY state
ORDER BY total_storm_events DESC
LIMIT 5;
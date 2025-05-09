WITH daily_counts AS (
  SELECT
    `date`,
    COUNT(DISTINCT unique_key) AS incidents
  FROM `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE UPPER(descript) = 'PUBLIC INTOXICATION'
  GROUP BY `date`
),
stats AS (
  SELECT
    AVG(incidents) AS mean_incidents,
    STDDEV_POP(incidents) AS std_incidents
  FROM daily_counts
),
ranked AS (
  SELECT
    FORMAT_DATE('%Y-%m-%d', d.`date`) AS date,
    ROW_NUMBER() OVER (
      ORDER BY (d.incidents - s.mean_incidents) / s.std_incidents DESC
    ) AS rn
  FROM daily_counts d
  CROSS JOIN stats s
)
SELECT
  date
FROM ranked
WHERE rn = 2;
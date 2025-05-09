WITH per_day AS (
  -- daily counts of Public Intoxication incidents in 2016
  SELECT
    `date` AS incident_date,
    COUNT(*) AS daily_cnt
  FROM `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE UPPER(`descript`) = 'PUBLIC INTOXICATION'
  GROUP BY incident_date
),
per_day_z AS (
  -- attach Z‑score for each day
  SELECT
    incident_date,
    daily_cnt,
    (daily_cnt - AVG(daily_cnt) OVER ()) /
    STDDEV_SAMP(daily_cnt) OVER () AS z_score
  FROM per_day
),
ranked AS (
  -- order by Z‑score (highest first)
  SELECT
    incident_date,
    z_score,
    ROW_NUMBER() OVER (ORDER BY z_score DESC, incident_date) AS rn
  FROM per_day_z
)
-- pick the second‑highest Z‑score date
SELECT
  FORMAT_DATE('%Y-%m-%d', incident_date) AS date
FROM ranked
WHERE rn = 2;
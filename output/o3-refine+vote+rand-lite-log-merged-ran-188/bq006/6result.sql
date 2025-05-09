WITH intox AS (
  SELECT
    `date` AS incident_date,
    COUNT(*) AS daily_count
  FROM
    `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE
    UPPER(`descript`) LIKE '%PUBLIC INTOXICATION%'
  GROUP BY
    incident_date
),
stats AS (
  SELECT
    AVG(daily_count)  AS mean_cnt,
    STDDEV_POP(daily_count) AS std_cnt
  FROM
    intox
),
zscores AS (
  SELECT
    incident_date,
    daily_count,
    (daily_count - mean_cnt) / std_cnt AS z_score
  FROM
    intox
  CROSS JOIN
    stats
)
SELECT
  FORMAT_DATE('%Y-%m-%d', incident_date) AS date
FROM
  zscores
ORDER BY
  z_score DESC,
  incident_date ASC
LIMIT 1 OFFSET 1;
WITH daily_counts AS (
  SELECT
    `date` AS incident_date,
    COUNT(*) AS daily_total
  FROM
    `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE
    UPPER(TRIM(descript)) = 'PUBLIC INTOXICATION'
  GROUP BY
    incident_date
),
stats AS (
  SELECT
    AVG(daily_total) AS avg_cnt,
    STDDEV_SAMP(daily_total) AS std_cnt
  FROM
    daily_counts
),
z_scores AS (
  SELECT
    incident_date,
    SAFE_DIVIDE(daily_total - stats.avg_cnt, stats.std_cnt) AS z_score
  FROM
    daily_counts
    CROSS JOIN stats
),
ranked AS (
  SELECT
    incident_date,
    z_score,
    ROW_NUMBER() OVER (ORDER BY z_score DESC) AS rn
  FROM
    z_scores
)
SELECT
  FORMAT_DATE('%Y-%m-%d', incident_date) AS incident_date
FROM
  ranked
WHERE
  rn = 2;
WITH daily_counts AS (
  SELECT
    `date`,
    COUNT(*) AS incident_cnt
  FROM
    `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE
    UPPER(descript) = 'PUBLIC INTOXICATION'
  GROUP BY
    `date`
),
stats AS (
  SELECT
    `date`,
    incident_cnt,
    AVG(incident_cnt)  OVER() AS mean_cnt,
    STDDEV_POP(incident_cnt) OVER() AS std_cnt
  FROM
    daily_counts
),
z_scored AS (
  SELECT
    `date`,
    (incident_cnt - mean_cnt) / std_cnt AS z_score
  FROM
    stats
)
SELECT
  FORMAT_DATE('%Y-%m-%d', `date`) AS date
FROM (
  SELECT
    `date`,
    z_score,
    ROW_NUMBER() OVER (ORDER BY z_score DESC, `date`) AS rn
  FROM
    z_scored
)
WHERE
  rn = 2;
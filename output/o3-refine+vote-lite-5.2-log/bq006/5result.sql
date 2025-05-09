WITH filtered AS (
  SELECT
    `date`
  FROM
    `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE
    UPPER(`descript`) = 'PUBLIC INTOXICATION'
),
daily_counts AS (
  SELECT
    `date`,
    COUNT(*) AS cnt
  FROM
    filtered
  GROUP BY
    `date`
),
stats AS (
  SELECT
    AVG(cnt) AS avg_cnt,
    STDDEV_POP(cnt) AS std_cnt
  FROM
    daily_counts
),
z_scores AS (
  SELECT
    `date`,
    cnt,
    (cnt - avg_cnt) / std_cnt AS z_score
  FROM
    daily_counts
  CROSS JOIN
    stats
)
SELECT
  FORMAT_DATE('%Y-%m-%d', `date`) AS incident_date
FROM
  z_scores
ORDER BY
  z_score DESC
LIMIT 1 OFFSET 1;
WITH daily_counts AS (
  SELECT
    `date`,
    COUNT(*) AS incident_count
  FROM `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE UPPER(descript) = 'PUBLIC INTOXICATION'
  GROUP BY `date`
),
stats AS (
  SELECT
    AVG(incident_count)  AS mean_cnt,
    STDDEV_POP(incident_count) AS stddev_cnt
  FROM daily_counts
),
z_scores AS (
  SELECT
    `date`,
    (incident_count - mean_cnt) / stddev_cnt AS z_score
  FROM daily_counts
  CROSS JOIN stats
)
SELECT
  FORMAT_DATE('%Y-%m-%d', `date`) AS `date`
FROM z_scores
ORDER BY z_score DESC, `date`
LIMIT 1 OFFSET 1;
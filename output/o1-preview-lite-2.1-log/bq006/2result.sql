WITH daily_counts AS (
  SELECT DATE(`timestamp`) AS `date`, COUNT(*) AS `incident_count`
  FROM `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE `descript` = 'PUBLIC INTOXICATION'
  GROUP BY `date`
),
stats AS (
  SELECT 
    AVG(incident_count) AS avg_count,
    STDDEV_POP(incident_count) AS stddev_count
  FROM daily_counts
),
z_scores AS (
  SELECT 
    date, 
    incident_count,
    ROUND((incident_count - stats.avg_count) / stats.stddev_count, 4) AS z_score
  FROM daily_counts, stats
)
SELECT date
FROM z_scores
ORDER BY z_score DESC
LIMIT 1 OFFSET 1
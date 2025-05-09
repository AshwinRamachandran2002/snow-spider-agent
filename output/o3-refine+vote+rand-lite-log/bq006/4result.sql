WITH daily_counts AS (
  SELECT
    `date` AS incident_date,
    COUNT(*) AS daily_total
  FROM `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE TRIM(UPPER(descript)) = 'PUBLIC INTOXICATION'
  GROUP BY incident_date
),
stats AS (
  SELECT
    incident_date,
    daily_total,
    AVG(daily_total)  OVER () AS mean_total,
    STDDEV_POP(daily_total) OVER () AS std_total
  FROM daily_counts
),
z_scores AS (
  SELECT
    incident_date,
    (daily_total - mean_total) / std_total AS z_score
  FROM stats
)
SELECT
  FORMAT_DATE('%Y-%m-%d', incident_date) AS date
FROM z_scores
QUALIFY ROW_NUMBER() OVER (ORDER BY z_score DESC, incident_date) = 2;
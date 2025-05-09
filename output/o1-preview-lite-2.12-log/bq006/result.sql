SELECT incident_date
FROM (
  SELECT
    incident_date,
    (daily_count - AVG(daily_count) OVER()) / STDDEV_SAMP(daily_count) OVER() AS z_score
  FROM (
    SELECT DATE(`timestamp`) AS incident_date, COUNT(*) AS daily_count
    FROM `bigquery-public-data.austin_incidents.incidents_2016`
    WHERE LOWER(descript) LIKE '%public intoxication%'
    GROUP BY incident_date
  )
)
ORDER BY z_score DESC
LIMIT 1 OFFSET 1
WITH daily AS (
  SELECT
    DATE(`timestamp`) AS incident_date,
    COUNT(*) AS cnt
  FROM `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE LOWER(`descript`) LIKE '%public%intox%'
  GROUP BY incident_date
),
stats AS (
  SELECT
    AVG(cnt) AS mean_cnt,
    STDDEV_POP(cnt) AS sd_cnt
  FROM daily
),
ranked AS (
  SELECT
    incident_date,
    cnt,
    (cnt - mean_cnt) / sd_cnt AS zscore,
    ROW_NUMBER() OVER (ORDER BY (cnt - mean_cnt) / sd_cnt DESC) AS rnk
  FROM daily, stats
)
SELECT FORMAT_DATE('%Y-%m-%d', incident_date) AS incident_date
FROM ranked
WHERE rnk = 2;
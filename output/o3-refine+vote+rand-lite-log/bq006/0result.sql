WITH intox AS (
  SELECT
    DATE(timestamp) AS incident_date
  FROM
    `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE
    UPPER(TRIM(descript)) = 'PUBLIC INTOXICATION'
),
daily_counts AS (
  SELECT
    incident_date,
    COUNT(*) AS cnt
  FROM
    intox
  GROUP BY
    incident_date
),
stats AS (
  SELECT
    AVG(cnt) AS mean_cnt,
    STDDEV_POP(cnt) AS std_cnt
  FROM
    daily_counts
),
scored AS (
  SELECT
    incident_date,
    cnt,
    SAFE_DIVIDE(cnt - mean_cnt, std_cnt) AS z_score,
    ROW_NUMBER() OVER (ORDER BY SAFE_DIVIDE(cnt - mean_cnt, std_cnt) DESC, incident_date) AS rn
  FROM
    daily_counts, stats
)
SELECT
  FORMAT_DATE('%Y-%m-%d', incident_date) AS incident_date
FROM
  scored
WHERE
  rn = 2;
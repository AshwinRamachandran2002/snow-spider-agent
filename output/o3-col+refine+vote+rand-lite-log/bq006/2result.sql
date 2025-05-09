WITH daily_counts AS (
  SELECT
    `date`,
    COUNT(*) AS cnt
  FROM `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE UPPER(`descript`) = 'PUBLIC INTOXICATION'
  GROUP BY `date`
),
stats AS (
  SELECT
    AVG(cnt)   AS mean_cnt,
    STDDEV(cnt) AS stddev_cnt
  FROM daily_counts
),
ranked AS (
  SELECT
    d.`date`,
    (d.cnt - s.mean_cnt) / s.stddev_cnt AS z_score,
    ROW_NUMBER() OVER (ORDER BY (d.cnt - s.mean_cnt) / s.stddev_cnt DESC) AS rn
  FROM daily_counts AS d
  CROSS JOIN stats AS s
)
SELECT
  FORMAT_DATE('%Y-%m-%d', `date`) AS `date`
FROM ranked
WHERE rn = 2;
WITH daily AS (
  SELECT
    `date`,
    COUNT(*) AS cnt
  FROM `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE UPPER(`descript`) = 'PUBLIC INTOXICATION'
  GROUP BY `date`
),
stats AS (
  SELECT
    AVG(cnt) AS mean_cnt,
    STDDEV_POP(cnt) AS stddev_cnt
  FROM daily
),
ranked AS (
  SELECT
    d.`date`,
    ROW_NUMBER() OVER (ORDER BY (d.cnt - s.mean_cnt) / s.stddev_cnt DESC) AS rn
  FROM daily d
  CROSS JOIN stats s
)
SELECT
  `date`
FROM ranked
WHERE rn = 2;
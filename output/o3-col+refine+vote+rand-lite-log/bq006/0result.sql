WITH daily AS (
  SELECT
    `date`,
    COUNT(*) AS daily_cnt
  FROM
    `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE
    UPPER(`descript`) = 'PUBLIC INTOXICATION'
  GROUP BY
    `date`
),
stats AS (
  SELECT
    AVG(daily_cnt) AS mean_cnt,
    STDDEV_POP(daily_cnt) AS stddev_cnt
  FROM
    daily
),
ranked AS (
  SELECT
    d.`date`,
    (d.daily_cnt - s.mean_cnt) / s.stddev_cnt AS z_score,
    ROW_NUMBER() OVER (ORDER BY (d.daily_cnt - s.mean_cnt) / s.stddev_cnt DESC) AS rn
  FROM
    daily d
    CROSS JOIN stats s
)
SELECT
  FORMAT_DATE('%F', `date`) AS `2016-date-with-second-highest-zscore`
FROM
  ranked
WHERE
  rn = 2;
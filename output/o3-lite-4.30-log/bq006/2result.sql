WITH daily AS (
  SELECT
    date,
    COUNT(*) AS cnt
  FROM `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE UPPER(descript) = 'PUBLIC INTOXICATION'
  GROUP BY date
),
stats AS (
  SELECT
    AVG(cnt) AS avg_cnt,
    STDDEV_POP(cnt) AS std_cnt
  FROM daily
),
scored AS (
  SELECT
    d.date,
    (d.cnt - s.avg_cnt) / s.std_cnt AS z_score
  FROM daily d
  CROSS JOIN stats s
)
SELECT
  FORMAT_DATE('%F', date) AS date
FROM (
  SELECT
    date,
    DENSE_RANK() OVER (ORDER BY z_score DESC) AS z_rank
  FROM scored
)
WHERE z_rank = 2;
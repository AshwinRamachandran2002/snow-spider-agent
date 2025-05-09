WITH daily AS (
  SELECT
    `date`,
    COUNT(*) AS cnt
  FROM `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE LOWER(`descript`) = 'public intoxication'
  GROUP BY `date`
),
stats AS (
  SELECT
    AVG(cnt)   AS mean_cnt,
    STDDEV(cnt) AS std_cnt
  FROM daily
)
SELECT
  FORMAT_DATE('%Y-%m-%d', d.`date`) AS `date`
FROM daily AS d
CROSS JOIN stats AS s
ORDER BY (d.cnt - s.mean_cnt) / s.std_cnt DESC
LIMIT 1 OFFSET 1;
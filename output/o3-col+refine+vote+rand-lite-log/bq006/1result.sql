WITH daily AS (
  SELECT
    `date`,
    COUNT(*) AS daily_cnt
  FROM `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE UPPER(TRIM(`descript`)) = 'PUBLIC INTOXICATION'
  GROUP BY `date`
),
stats AS (
  SELECT
    AVG(daily_cnt)    AS avg_cnt,
    STDDEV_POP(daily_cnt) AS std_cnt
  FROM daily
),
ranked AS (
  SELECT
    d.`date`,
    (d.daily_cnt - s.avg_cnt) / s.std_cnt AS z_score,
    ROW_NUMBER() OVER (ORDER BY (d.daily_cnt - s.avg_cnt) / s.std_cnt DESC) AS rn
  FROM daily d
  CROSS JOIN stats s
)
SELECT
  CAST(`date` AS STRING) AS `2016_date_with_second_highest_zscore`
FROM ranked
WHERE rn = 2;
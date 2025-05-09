WITH daily_counts AS (
  SELECT
    `date`,
    COUNT(*) AS cnt
  FROM `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE UPPER(`descript`) = 'PUBLIC INTOXICATION'
  GROUP BY `date`
),
z_scores AS (
  SELECT
    `date`,
    cnt,
    (cnt - AVG(cnt) OVER()) / STDDEV_POP(cnt) OVER() AS z_score
  FROM daily_counts
)
SELECT
  FORMAT_DATE('%Y-%m-%d', `date`) AS second_highest_zscore_date
FROM z_scores
ORDER BY z_score DESC
LIMIT 1
OFFSET 1;
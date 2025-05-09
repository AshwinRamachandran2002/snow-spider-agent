WITH daily AS (
  SELECT
    `date`,
    COUNT(*) AS cnt
  FROM `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE TRIM(UPPER(`descript`)) = 'PUBLIC INTOXICATION'
  GROUP BY `date`
),
scored AS (
  SELECT
    `date`,
    (cnt - AVG(cnt) OVER()) / STDDEV_POP(cnt) OVER() AS z_score
  FROM daily
)
SELECT
  FORMAT_DATE('%Y-%m-%d', `date`) AS date_with_second_highest_z
FROM scored
ORDER BY z_score DESC
LIMIT 1 OFFSET 1;
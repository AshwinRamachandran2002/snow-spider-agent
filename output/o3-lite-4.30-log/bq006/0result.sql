SELECT
  `date`
FROM (
  SELECT
    `date`,
    SAFE_DIVIDE(
      COUNT(*) - AVG(COUNT(*)) OVER (),
      STDDEV_POP(COUNT(*)) OVER ()
    ) AS z_score
  FROM `bigquery-public-data.austin_incidents.incidents_2016`
  WHERE descript = 'PUBLIC INTOXICATION'
  GROUP BY `date`
)
ORDER BY z_score DESC, `date`
LIMIT 1 OFFSET 1;
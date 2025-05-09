SELECT second_highest_zscore_date
FROM (
  WITH daily AS (
    SELECT
      date,
      COUNT(*) AS daily_cnt
    FROM `bigquery-public-data.austin_incidents.incidents_2016`
    WHERE descript = 'PUBLIC INTOXICATION'
    GROUP BY date
  ),
  stats AS (
    SELECT
      AVG(daily_cnt)  AS avg_cnt,
      STDDEV_POP(daily_cnt) AS std_cnt
    FROM daily
  ),
  scored AS (
    SELECT
      d.date,
      (d.daily_cnt - s.avg_cnt)/s.std_cnt AS z_score
    FROM daily AS d
    CROSS JOIN stats AS s
  ),
  ranked AS (
    SELECT
      date,
      ROW_NUMBER() OVER (ORDER BY z_score DESC) AS rn
    FROM scored
  )
  SELECT FORMAT_DATE('%Y-%m-%d', date) AS second_highest_zscore_date
  FROM ranked
  WHERE rn = 2
);
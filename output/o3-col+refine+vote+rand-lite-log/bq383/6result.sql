-- Highest PRCP, lowest TMIN, and highest TMAX for the last 15 days of each year 2013-2016
WITH combined AS (
  SELECT 2013 AS yr, id, date, element, value, qflag
  FROM `bigquery-public-data.ghcn_d.ghcnd_2013`
  UNION ALL
  SELECT 2014 AS yr, id, date, element, value, qflag
  FROM `bigquery-public-data.ghcn_d.ghcnd_2014`
  UNION ALL
  SELECT 2015 AS yr, id, date, element, value, qflag
  FROM `bigquery-public-data.ghcn_d.ghcnd_2015`
  UNION ALL
  SELECT 2016 AS yr, id, date, element, value, qflag
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
)
SELECT
  yr AS year,
  MAX(CASE WHEN element = 'PRCP' THEN value END) / 10.0 AS max_precip_mm,
  MIN(CASE WHEN element = 'TMIN' THEN value END) / 10.0 AS min_tmin_c,
  MAX(CASE WHEN element = 'TMAX' THEN value END) / 10.0 AS max_tmax_c
FROM combined
WHERE id = 'USW00094846'
  AND element IN ('PRCP', 'TMIN', 'TMAX')
  AND qflag IS NULL
  AND value IS NOT NULL
  AND date BETWEEN DATE(yr, 12, 17) AND DATE(yr, 12, 31)
GROUP BY year
ORDER BY year;
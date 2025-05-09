-- Highest precipitation (mm), lowest TMIN (°C) and highest TMAX (°C)
-- for 17-31 December of each year 2013-2016 at station USW00094846
WITH daily AS (
  -- 2013
  SELECT 2013 AS yr, element, value
  FROM `bigquery-public-data.ghcn_d.ghcnd_2013`
  WHERE id = 'USW00094846'
    AND qflag IS NULL
    AND date BETWEEN '2013-12-17' AND '2013-12-31'
    AND element IN ('PRCP','TMIN','TMAX')
  UNION ALL
  -- 2014
  SELECT 2014, element, value
  FROM `bigquery-public-data.ghcn_d.ghcnd_2014`
  WHERE id = 'USW00094846'
    AND qflag IS NULL
    AND date BETWEEN '2014-12-17' AND '2014-12-31'
    AND element IN ('PRCP','TMIN','TMAX')
  UNION ALL
  -- 2015
  SELECT 2015, element, value
  FROM `bigquery-public-data.ghcn_d.ghcnd_2015`
  WHERE id = 'USW00094846'
    AND qflag IS NULL
    AND date BETWEEN '2015-12-17' AND '2015-12-31'
    AND element IN ('PRCP','TMIN','TMAX')
  UNION ALL
  -- 2016
  SELECT 2016, element, value
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE id = 'USW00094846'
    AND qflag IS NULL
    AND date BETWEEN '2016-12-17' AND '2016-12-31'
    AND element IN ('PRCP','TMIN','TMAX')
)
SELECT
  yr,
  MAX(CASE WHEN element = 'PRCP' THEN value END) / 10 AS max_prcp_mm,
  MIN(CASE WHEN element = 'TMIN' THEN value END) / 10 AS min_temp_c,
  MAX(CASE WHEN element = 'TMAX' THEN value END) / 10 AS max_temp_c
FROM daily
GROUP BY yr
ORDER BY yr;
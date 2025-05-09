/*  Peak precipitation (mm), coldest TMIN (°C) and warmest TMAX (°C)
    recorded during 17-31 Dec of each year 2013-2016 at station USW00094846.  */

WITH last15 AS (
  -- 2013 -------------------------------------------------------------------
  SELECT 2013 AS year, element, value/10.0 AS val
  FROM `bigquery-public-data.ghcn_d.ghcnd_2013`
  WHERE id = 'USW00094846'
    AND element IN ('PRCP', 'TMIN', 'TMAX')
    AND qflag IS NULL
    AND date BETWEEN DATE '2013-12-17' AND DATE '2013-12-31'

  UNION ALL
  -- 2014 -------------------------------------------------------------------
  SELECT 2014, element, value/10.0
  FROM `bigquery-public-data.ghcn_d.ghcnd_2014`
  WHERE id = 'USW00094846'
    AND element IN ('PRCP', 'TMIN', 'TMAX')
    AND qflag IS NULL
    AND date BETWEEN DATE '2014-12-17' AND DATE '2014-12-31'

  UNION ALL
  -- 2015 -------------------------------------------------------------------
  SELECT 2015, element, value/10.0
  FROM `bigquery-public-data.ghcn_d.ghcnd_2015`
  WHERE id = 'USW00094846'
    AND element IN ('PRCP', 'TMIN', 'TMAX')
    AND qflag IS NULL
    AND date BETWEEN DATE '2015-12-17' AND DATE '2015-12-31'

  UNION ALL
  -- 2016 -------------------------------------------------------------------
  SELECT 2016, element, value/10.0
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
  WHERE id = 'USW00094846'
    AND element IN ('PRCP', 'TMIN', 'TMAX')
    AND qflag IS NULL
    AND date BETWEEN DATE '2016-12-17' AND DATE '2016-12-31'
)

SELECT
  year,
  ROUND(MAX(IF(element = 'PRCP', val, NULL)), 4) AS highest_prcp_mm,
  ROUND(MIN(IF(element = 'TMIN', val, NULL)), 4) AS lowest_tmin_c,
  ROUND(MAX(IF(element = 'TMAX', val, NULL)), 4) AS highest_tmax_c
FROM last15
GROUP BY year
ORDER BY year;
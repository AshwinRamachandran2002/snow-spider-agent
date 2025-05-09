WITH all_years AS (
  SELECT 2013 AS year, id, date, element, value, qflag
  FROM `bigquery-public-data.ghcn_d.ghcnd_2013`
  UNION ALL
  SELECT 2014 AS year, id, date, element, value, qflag
  FROM `bigquery-public-data.ghcn_d.ghcnd_2014`
  UNION ALL
  SELECT 2015 AS year, id, date, element, value, qflag
  FROM `bigquery-public-data.ghcn_d.ghcnd_2015`
  UNION ALL
  SELECT 2016 AS year, id, date, element, value, qflag
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
)
SELECT
  year,
  ROUND(MAX(CASE WHEN element = 'PRCP' THEN value END) / 10, 4) AS max_precip_mm,
  ROUND(MIN(CASE WHEN element = 'TMIN' THEN value END) / 10, 4) AS min_temp_c,
  ROUND(MAX(CASE WHEN element = 'TMAX' THEN value END) / 10, 4) AS max_temp_c
FROM all_years
WHERE id = 'USW00094846'
  AND element IN ('PRCP', 'TMIN', 'TMAX')
  AND qflag IS NULL
  AND value IS NOT NULL
  AND EXTRACT(MONTH FROM date) = 12
  AND EXTRACT(DAY FROM date) BETWEEN 17 AND 31
GROUP BY year
ORDER BY year;
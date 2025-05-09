SELECT
  EXTRACT(YEAR FROM date) AS Year,
  ROUND(MAX(CASE WHEN element = 'PRCP' THEN value END) / 10, 4) AS Precipitation_mm,
  ROUND(MIN(CASE WHEN element = 'TMIN' THEN value END) / 10, 4) AS Minimum_Temperature_C,
  ROUND(MAX(CASE WHEN element = 'TMAX' THEN value END) / 10, 4) AS Maximum_Temperature_C
FROM (
  SELECT id, date, element, value, qflag FROM `bigquery-public-data.ghcn_d.ghcnd_2013`
  UNION ALL
  SELECT id, date, element, value, qflag FROM `bigquery-public-data.ghcn_d.ghcnd_2014`
  UNION ALL
  SELECT id, date, element, value, qflag FROM `bigquery-public-data.ghcn_d.ghcnd_2015`
  UNION ALL
  SELECT id, date, element, value, qflag FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
) AS all_data
WHERE id = 'USW00094846'
  AND EXTRACT(MONTH FROM date) = 12
  AND EXTRACT(DAY FROM date) BETWEEN 17 AND 31
  AND element IN ('PRCP', 'TMIN', 'TMAX')
  AND (qflag IS NULL OR qflag = '')
GROUP BY Year
ORDER BY Year;
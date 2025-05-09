SELECT
  CAST(year AS INT64)                                                          AS year,
  ROUND(MAX(CASE WHEN element = 'PRCP' THEN value END) / 10, 4) AS max_precip_mm,
  ROUND(MIN(CASE WHEN element = 'TMIN' THEN value END) / 10, 4) AS min_temp_c,
  ROUND(MAX(CASE WHEN element = 'TMAX' THEN value END) / 10, 4) AS max_temp_c
FROM (
  SELECT '2013' AS year, id, date, element, value, qflag FROM `bigquery-public-data.ghcn_d.ghcnd_2013`
  UNION ALL
  SELECT '2014', id, date, element, value, qflag FROM `bigquery-public-data.ghcn_d.ghcnd_2014`
  UNION ALL
  SELECT '2015', id, date, element, value, qflag FROM `bigquery-public-data.ghcn_d.ghcnd_2015`
  UNION ALL
  SELECT '2016', id, date, element, value, qflag FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
) AS all_years
WHERE id = 'USW00094846'
  AND qflag IS NULL
  AND element IN ('PRCP', 'TMAX', 'TMIN')
  AND EXTRACT(MONTH FROM date) = 12
  AND EXTRACT(DAY FROM date)  >= 17
GROUP BY year
ORDER BY year;
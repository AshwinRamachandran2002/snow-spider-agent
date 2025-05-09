SELECT
  Year,
  ROUND(MAX(CASE WHEN element = 'PRCP' THEN value END) / 10.0, 4) AS Precipitation_mm,
  ROUND(MIN(CASE WHEN element = 'TMIN' THEN value END) / 10.0, 4) AS Minimum_Temperature_C,
  ROUND(MAX(CASE WHEN element = 'TMAX' THEN value END) / 10.0, 4) AS Maximum_Temperature_C
FROM (
  SELECT '2013' AS Year, id, date, element, value, qflag
  FROM `bigquery-public-data.ghcn_d.ghcnd_2013`
  UNION ALL
  SELECT '2014' AS Year, id, date, element, value, qflag
  FROM `bigquery-public-data.ghcn_d.ghcnd_2014`
  UNION ALL
  SELECT '2015' AS Year, id, date, element, value, qflag
  FROM `bigquery-public-data.ghcn_d.ghcnd_2015`
  UNION ALL
  SELECT '2016' AS Year, id, date, element, value, qflag
  FROM `bigquery-public-data.ghcn_d.ghcnd_2016`
) AS all_data
WHERE id = 'USW00094846'
  AND date BETWEEN DATE_SUB(DATE(CONCAT(Year, '-12-31')), INTERVAL 14 DAY) AND DATE(CONCAT(Year, '-12-31'))
  AND element IN ('PRCP', 'TMIN', 'TMAX')
  AND (qflag IS NULL OR qflag = '')
  AND value IS NOT NULL
GROUP BY Year
ORDER BY Year;
SELECT
  CAST(_TABLE_SUFFIX AS INT64)                          AS year,
  MAX(CASE WHEN element = 'PRCP' THEN value END) / 10   AS highest_precip_mm,  -- 1/10 mm → mm
  MIN(CASE WHEN element = 'TMIN' THEN value END) / 10   AS coldest_tmin_c,     -- 1/10 °C → °C
  MAX(CASE WHEN element = 'TMAX' THEN value END) / 10   AS hottest_tmax_c      -- 1/10 °C → °C
FROM `bigquery-public-data.ghcn_d.ghcnd_*`
WHERE _TABLE_SUFFIX IN ('2013','2014','2015','2016')
  AND id      = 'USW00094846'
  AND element IN ('PRCP','TMIN','TMAX')
  AND date BETWEEN DATE(CONCAT(_TABLE_SUFFIX,'-12-17'))
               AND DATE(CONCAT(_TABLE_SUFFIX,'-12-31'))
  AND qflag IS NULL
  AND mflag IS NULL
GROUP BY year
ORDER BY year;
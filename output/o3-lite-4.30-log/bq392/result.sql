SELECT
  FORMAT('%s-%02d-%02d', year, CAST(mo AS INT64), CAST(da AS INT64)) AS date
FROM
  `bigquery-public-data.noaa_gsod.gsod2009`
WHERE
  stn = '723758'
  AND mo  = '10'
  AND temp < 9999.9
GROUP BY
  date
ORDER BY
  AVG(temp) DESC,
  date
LIMIT 3;
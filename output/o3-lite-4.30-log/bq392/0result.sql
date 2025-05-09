SELECT
  FORMAT('%s-%s-%s', g.year, LPAD(g.mo, 2, '0'), LPAD(g.da, 2, '0')) AS date
FROM `bigquery-public-data.noaa_gsod.gsod2009` AS g
WHERE g.stn = '723758'
  AND g.year = '2009'
  AND g.mo   = '10'
  AND g.temp <> 9999.9
ORDER BY g.temp DESC, g.da
LIMIT 3;
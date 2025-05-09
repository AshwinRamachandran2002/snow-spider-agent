SELECT
  CONCAT(`year`, '-', LPAD(`mo`, 2, '0'), '-', LPAD(`da`, 2, '0')) AS `date`
FROM `bigquery-public-data.noaa_gsod.gsod2009`
WHERE `stn` = '723758'
  AND `mo`  = '10'
GROUP BY `date`
ORDER BY AVG(`temp`) DESC
LIMIT 3;
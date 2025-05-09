SELECT FORMAT_DATE('%Y-%m-%d',
                   DATE(CAST(`year` AS INT64),
                        CAST(`mo`   AS INT64),
                        CAST(`da`   AS INT64))) AS hottest_date
FROM `bigquery-public-data.noaa_gsod.gsod2009`
WHERE `stn`  = '723758'
  AND `year` = '2009'
  AND `mo`   = '10'
  AND `temp` < 9999                -- exclude missing-value sentinel
ORDER BY `temp` DESC
LIMIT 3;
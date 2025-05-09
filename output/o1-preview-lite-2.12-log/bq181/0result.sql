SELECT
  ROUND((COUNTIF(valid_days >= 329) * 100.0) / COUNT(*), 4) AS Percentage_of_Stations
FROM (
  SELECT `stn`,
         COUNTIF(`temp` IS NOT NULL AND `temp` != 9999.9) AS valid_days
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  GROUP BY `stn`
)
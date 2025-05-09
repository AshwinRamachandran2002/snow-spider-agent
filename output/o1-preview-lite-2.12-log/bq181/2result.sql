SELECT
  ROUND((COUNTIF(valid_temp_days >= 329) / COUNT(*)) * 100, 4) AS Percentage_of_Stations
FROM (
  SELECT
    stn,
    COUNT(DISTINCT PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0')))) AS valid_temp_days
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE temp != 9999.9
  GROUP BY stn
);
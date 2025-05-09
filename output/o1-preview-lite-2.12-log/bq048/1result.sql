WITH complaint_totals AS (
  SELECT 
    complaint_type, 
    COUNT(*) AS total_requests
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
  GROUP BY complaint_type
  HAVING COUNT(*) > 3000
),
daily_complaints AS (
  SELECT
    DATE(created_date) AS complaint_date,
    complaint_type,
    COUNT(*) AS daily_type_complaints
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
  GROUP BY complaint_date, complaint_type
),
daily_total_complaints AS (
  SELECT
    DATE(created_date) AS complaint_date,
    COUNT(*) AS daily_total_complaints
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
  GROUP BY complaint_date
),
daily_proportions AS (
  SELECT
    dc.complaint_date,
    dc.complaint_type,
    dc.daily_type_complaints / dtc.daily_total_complaints AS daily_proportion
  FROM daily_complaints dc
  JOIN daily_total_complaints dtc ON dc.complaint_date = dtc.complaint_date
  WHERE dc.complaint_type IN (SELECT complaint_type FROM complaint_totals)
),
gsod_data AS (
  SELECT stn, year, mo, da, wdsp FROM `bigquery-public-data.noaa_gsod.gsod2011` WHERE stn = '744860'
  UNION ALL
  SELECT stn, year, mo, da, wdsp FROM `bigquery-public-data.noaa_gsod.gsod2012` WHERE stn = '744860'
  UNION ALL
  SELECT stn, year, mo, da, wdsp FROM `bigquery-public-data.noaa_gsod.gsod2013` WHERE stn = '744860'
  UNION ALL
  SELECT stn, year, mo, da, wdsp FROM `bigquery-public-data.noaa_gsod.gsod2014` WHERE stn = '744860'
  UNION ALL
  SELECT stn, year, mo, da, wdsp FROM `bigquery-public-data.noaa_gsod.gsod2015` WHERE stn = '744860'
  UNION ALL
  SELECT stn, year, mo, da, wdsp FROM `bigquery-public-data.noaa_gsod.gsod2016` WHERE stn = '744860'
  UNION ALL
  SELECT stn, year, mo, da, wdsp FROM `bigquery-public-data.noaa_gsod.gsod2017` WHERE stn = '744860'
  UNION ALL
  SELECT stn, year, mo, da, wdsp FROM `bigquery-public-data.noaa_gsod.gsod2018` WHERE stn = '744860'
  UNION ALL
  SELECT stn, year, mo, da, wdsp FROM `bigquery-public-data.noaa_gsod.gsod2019` WHERE stn = '744860'
  UNION ALL
  SELECT stn, year, mo, da, wdsp FROM `bigquery-public-data.noaa_gsod.gsod2020` WHERE stn = '744860'
),
wind_data AS (
  SELECT
    DATE(CONCAT(year, '-', LPAD(mo,2,'0'), '-', LPAD(da,2,'0'))) AS complaint_date,
    SAFE_CAST(wdsp AS FLOAT64) AS wdsp
  FROM gsod_data
  WHERE SAFE_CAST(wdsp AS FLOAT64) IS NOT NULL AND SAFE_CAST(wdsp AS FLOAT64) != 999.9
),
complaint_wind AS (
  SELECT
    dp.complaint_type,
    dp.complaint_date,
    dp.daily_proportion,
    wd.wdsp
  FROM daily_proportions dp
  JOIN wind_data wd ON dp.complaint_date = wd.complaint_date
)
SELECT
  complaint_type,
  ROUND(CORR(daily_proportion, wdsp), 4) AS correlation_coefficient
FROM complaint_wind
GROUP BY complaint_type
HAVING COUNT(*) > 0
ORDER BY correlation_coefficient DESC;
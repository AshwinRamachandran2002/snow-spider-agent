WITH complaint_types AS (
  SELECT complaint_type
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
  GROUP BY complaint_type
  HAVING COUNT(*) > 3000
),
daily_complaints AS (
  SELECT
    DATE(created_date) AS complaint_date,
    complaint_type,
    COUNT(*) AS daily_complaint_count
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
  GROUP BY complaint_date, complaint_type
),
daily_totals AS (
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
    SAFE_DIVIDE(dc.daily_complaint_count, dt.daily_total_complaints) AS complaint_proportion
  FROM daily_complaints dc
  JOIN daily_totals dt ON dc.complaint_date = dt.complaint_date
  WHERE dc.complaint_type IN (SELECT complaint_type FROM complaint_types)
),
weather_data AS (
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da)) AS weather_date,
    CAST(wdsp AS FLOAT64) AS wind_speed
  FROM `bigquery-public-data.noaa_gsod.gsod2011` WHERE stn = '744860'
  UNION ALL
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da)) AS weather_date,
    CAST(wdsp AS FLOAT64) AS wind_speed
  FROM `bigquery-public-data.noaa_gsod.gsod2012` WHERE stn = '744860'
  UNION ALL
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da)) AS weather_date,
    CAST(wdsp AS FLOAT64) AS wind_speed
  FROM `bigquery-public-data.noaa_gsod.gsod2013` WHERE stn = '744860'
  UNION ALL
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da)) AS weather_date,
    CAST(wdsp AS FLOAT64) AS wind_speed
  FROM `bigquery-public-data.noaa_gsod.gsod2014` WHERE stn = '744860'
  UNION ALL
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da)) AS weather_date,
    CAST(wdsp AS FLOAT64) AS wind_speed
  FROM `bigquery-public-data.noaa_gsod.gsod2015` WHERE stn = '744860'
  UNION ALL
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da)) AS weather_date,
    CAST(wdsp AS FLOAT64) AS wind_speed
  FROM `bigquery-public-data.noaa_gsod.gsod2016` WHERE stn = '744860'
  UNION ALL
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da)) AS weather_date,
    CAST(wdsp AS FLOAT64) AS wind_speed
  FROM `bigquery-public-data.noaa_gsod.gsod2017` WHERE stn = '744860'
  UNION ALL
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da)) AS weather_date,
    CAST(wdsp AS FLOAT64) AS wind_speed
  FROM `bigquery-public-data.noaa_gsod.gsod2018` WHERE stn = '744860'
  UNION ALL
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da)) AS weather_date,
    CAST(wdsp AS FLOAT64) AS wind_speed
  FROM `bigquery-public-data.noaa_gsod.gsod2019` WHERE stn = '744860'
  UNION ALL
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da)) AS weather_date,
    CAST(wdsp AS FLOAT64) AS wind_speed
  FROM `bigquery-public-data.noaa_gsod.gsod2020` WHERE stn = '744860'
),
complaint_weather AS (
  SELECT
    dp.complaint_type,
    dp.complaint_date,
    dp.complaint_proportion,
    wd.wind_speed
  FROM daily_proportions dp
  JOIN weather_data wd ON dp.complaint_date = wd.weather_date
  WHERE wd.wind_speed <> 999.9
)
SELECT
  complaint_type,
  ROUND(CORR(complaint_proportion, wind_speed), 4) AS correlation_coefficient
FROM complaint_weather
GROUP BY complaint_type
ORDER BY correlation_coefficient DESC;
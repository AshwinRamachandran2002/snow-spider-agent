WITH temp_data AS (
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo, 2, '0'), LPAD(da, 2, '0'))) AS date,
    AVG(temp) AS avg_temp
  FROM (
    SELECT stn, year, mo, da, temp
    FROM `bigquery-public-data.noaa_gsod.gsod2008`
    WHERE stn IN ('725030', '744860') AND temp != 9999.9
    UNION ALL
    SELECT stn, year, mo, da, temp
    FROM `bigquery-public-data.noaa_gsod.gsod2009`
    WHERE stn IN ('725030', '744860') AND temp != 9999.9
    UNION ALL
    SELECT stn, year, mo, da, temp
    FROM `bigquery-public-data.noaa_gsod.gsod2010`
    WHERE stn IN ('725030', '744860') AND temp != 9999.9
    UNION ALL
    SELECT stn, year, mo, da, temp
    FROM `bigquery-public-data.noaa_gsod.gsod2011`
    WHERE stn IN ('725030', '744860') AND temp != 9999.9
    UNION ALL
    SELECT stn, year, mo, da, temp
    FROM `bigquery-public-data.noaa_gsod.gsod2012`
    WHERE stn IN ('725030', '744860') AND temp != 9999.9
    UNION ALL
    SELECT stn, year, mo, da, temp
    FROM `bigquery-public-data.noaa_gsod.gsod2013`
    WHERE stn IN ('725030', '744860') AND temp != 9999.9
    UNION ALL
    SELECT stn, year, mo, da, temp
    FROM `bigquery-public-data.noaa_gsod.gsod2014`
    WHERE stn IN ('725030', '744860') AND temp != 9999.9
    UNION ALL
    SELECT stn, year, mo, da, temp
    FROM `bigquery-public-data.noaa_gsod.gsod2015`
    WHERE stn IN ('725030', '744860') AND temp != 9999.9
    UNION ALL
    SELECT stn, year, mo, da, temp
    FROM `bigquery-public-data.noaa_gsod.gsod2016`
    WHERE stn IN ('725030', '744860') AND temp != 9999.9
    UNION ALL
    SELECT stn, year, mo, da, temp
    FROM `bigquery-public-data.noaa_gsod.gsod2017`
    WHERE stn IN ('725030', '744860') AND temp != 9999.9
  )
  GROUP BY date
),
total_complaints AS (
  SELECT complaint_type,
         COUNT(*) AS total_complaints
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE DATE(created_date) BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY complaint_type
  HAVING COUNT(*) > 5000
),
complaint_counts AS (
  SELECT DATE(created_date) AS date,
         complaint_type,
         COUNT(*) AS daily_count
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE DATE(created_date) BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY date, complaint_type
),
filtered_complaint_counts AS (
  SELECT c.date, c.complaint_type, c.daily_count
  FROM complaint_counts c
  JOIN total_complaints t ON c.complaint_type = t.complaint_type
),
daily_totals AS (
  SELECT date, SUM(daily_count) AS total_daily_complaints
  FROM filtered_complaint_counts
  GROUP BY date
),
complaint_percentages AS (
  SELECT c.date,
         c.complaint_type,
         c.daily_count,
         d.total_daily_complaints,
         c.daily_count / d.total_daily_complaints AS daily_percentage
  FROM filtered_complaint_counts c
  JOIN daily_totals d ON c.date = d.date
),
joined_data AS (
  SELECT cp.complaint_type,
         cp.date,
         cp.daily_count,
         cp.daily_percentage,
         td.avg_temp
  FROM complaint_percentages cp
  JOIN temp_data td ON cp.date = td.date
),
stats AS (
  SELECT
    complaint_type,
    SUM(daily_count) AS total_complaints,
    COUNT(*) AS total_days_with_valid_temperature_records,
    ROUND(CORR(daily_count, avg_temp), 4) AS pearson_correlation_count_temperature,
    ROUND(CORR(daily_percentage, avg_temp), 4) AS pearson_correlation_percentage_temperature
  FROM joined_data
  GROUP BY complaint_type
),
result AS (
  SELECT *
  FROM stats
  WHERE ABS(pearson_correlation_count_temperature) > 0.5 OR ABS(pearson_correlation_percentage_temperature) > 0.5
)
SELECT
  complaint_type AS Complaint_Type,
  total_complaints AS Total_Complaints,
  total_days_with_valid_temperature_records AS Total_Days_with_Valid_Temperature_Records,
  pearson_correlation_count_temperature AS Pearson_Correlation_Count_Temperature,
  pearson_correlation_percentage_temperature AS Pearson_Correlation_Percentage_Temperature
FROM result
ORDER BY Total_Complaints DESC;
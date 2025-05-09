WITH temperature_data AS (
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0'))) AS date,
    AVG(temp) AS mean_temp
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2008' AND '2017'
    AND stn IN ('725030', '744860')
    AND temp != 9999.9
  GROUP BY date
),
complaint_data AS (
  SELECT
    DATE(created_date) AS date,
    complaint_type,
    COUNT(*) AS complaint_count
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2008 AND 2017
    AND latitude IS NOT NULL AND longitude IS NOT NULL
    AND (
      ST_DWithin(ST_GEOGPOINT(longitude, latitude), ST_GEOGPOINT(-73.8740, 40.7769), 5000)
      OR ST_DWithin(ST_GEOGPOINT(longitude, latitude), ST_GEOGPOINT(-73.7781, 40.6413), 5000)
    )
  GROUP BY date, complaint_type
),
total_complaints_per_day AS (
  SELECT
    date,
    SUM(complaint_count) AS total_complaints
  FROM complaint_data
  GROUP BY date
),
combined_data AS (
  SELECT
    c.date,
    c.complaint_type,
    c.complaint_count,
    t.mean_temp,
    tc.total_complaints,
    SAFE_DIVIDE(c.complaint_count, tc.total_complaints) AS complaint_percentage
  FROM complaint_data c
  JOIN temperature_data t ON c.date = t.date
  JOIN total_complaints_per_day tc ON c.date = tc.date
)
SELECT
  complaint_type,
  SUM(complaint_count) AS Total_Complaint_Count,
  COUNT(DISTINCT date) AS Total_Day_Count,
  ROUND(CORR(mean_temp, complaint_count), 4) AS Pearson_Correlation_Count,
  ROUND(CORR(mean_temp, complaint_percentage), 4) AS Pearson_Correlation_Percentage
FROM combined_data
GROUP BY complaint_type
HAVING
  SUM(complaint_count) > 5000
  AND (ABS(ROUND(CORR(mean_temp, complaint_count), 4)) > 0.5 OR ABS(ROUND(CORR(mean_temp, complaint_percentage), 4)) > 0.5)
ORDER BY complaint_type;
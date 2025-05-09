WITH temp_data AS (
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da)) AS date,
    AVG(temp) AS temp
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2008' AND '2018'
    AND ((stn = '744860' AND wban = '94789') OR (stn = '999999' AND wban = '14732'))
    AND temp != 9999.9
  GROUP BY date
),
complaints AS (
  SELECT
    DATE(created_date) AS date,
    complaint_type,
    COUNT(*) AS complaint_count
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2008-01-01' AND '2018-12-31'
    AND latitude IS NOT NULL AND longitude IS NOT NULL
    AND (
      ST_DISTANCE(
        ST_GEOGPOINT(longitude, latitude),
        ST_GEOGPOINT(-73.8800, 40.7790)  -- LaGuardia coordinates
      ) <= 5000 OR
      ST_DISTANCE(
        ST_GEOGPOINT(longitude, latitude),
        ST_GEOGPOINT(-73.7640, 40.6390)  -- JFK coordinates
      ) <= 5000
    )
  GROUP BY date, complaint_type
),
daily_total_complaints AS (
  SELECT
    date,
    SUM(complaint_count) AS total_complaints
  FROM complaints
  GROUP BY date
),
complaints_with_percentage AS (
  SELECT
    c.date,
    c.complaint_type,
    c.complaint_count,
    dt.total_complaints,
    SAFE_DIVIDE(c.complaint_count, dt.total_complaints) AS complaint_percentage
  FROM complaints c
  JOIN daily_total_complaints dt ON c.date = dt.date
),
complaint_stats AS (
  SELECT
    complaint_type,
    SUM(complaint_count) AS total_complaint_count,
    COUNT(DISTINCT date) AS total_day_count
  FROM complaints_with_percentage
  GROUP BY complaint_type
),
correlation_data AS (
  SELECT
    cwp.complaint_type,
    cs.total_complaint_count,
    cs.total_day_count,
    CORR(t.temp, cwp.complaint_count) AS corr_count,
    CORR(t.temp, cwp.complaint_percentage) AS corr_percentage
  FROM complaints_with_percentage cwp
  JOIN temp_data t ON cwp.date = t.date
  JOIN complaint_stats cs ON cwp.complaint_type = cs.complaint_type
  WHERE cs.total_complaint_count > 5000
  GROUP BY cwp.complaint_type, cs.total_complaint_count, cs.total_day_count
)
SELECT
  complaint_type,
  total_complaint_count AS Total_Complaint_Count,
  total_day_count AS Total_Day_Count,
  ROUND(corr_count, 4) AS Pearson_Correlation_Count,
  ROUND(corr_percentage, 4) AS Pearson_Correlation_Percentage
FROM correlation_data
WHERE ABS(corr_count) > 0.5 OR ABS(corr_percentage) > 0.5
ORDER BY complaint_type;
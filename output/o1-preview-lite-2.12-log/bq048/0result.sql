WITH complaint_types_over_3000 AS (
  SELECT complaint_type
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
  GROUP BY complaint_type
  HAVING COUNT(*) > 3000
),
daily_total_complaints AS (
  SELECT DATE(created_date) AS complaint_date, COUNT(*) AS total_complaints
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
  GROUP BY complaint_date
),
daily_complaint_counts AS (
  SELECT
    DATE(created_date) AS complaint_date,
    complaint_type,
    COUNT(*) AS complaint_count
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
    AND complaint_type IN (SELECT complaint_type FROM complaint_types_over_3000)
  GROUP BY complaint_date, complaint_type
),
daily_complaint_proportions AS (
  SELECT
    c.complaint_date,
    c.complaint_type,
    c.complaint_count,
    t.total_complaints,
    SAFE_DIVIDE(c.complaint_count, t.total_complaints) AS complaint_proportion
  FROM daily_complaint_counts c
  JOIN daily_total_complaints t
  ON c.complaint_date = t.complaint_date
),
wind_speed_data AS (
  SELECT
    PARSE_DATE('%Y-%m-%d', CONCAT(year, '-', LPAD(mo,2,'0'), '-', LPAD(da,2,'0'))) AS date,
    CAST(wdsp AS FLOAT64) AS avg_wind_speed
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'
    AND stn = '744860'
    AND CAST(wdsp AS FLOAT64) != 999.9
),
joined_data AS (
  SELECT
    dcp.complaint_date,
    dcp.complaint_type,
    dcp.complaint_proportion,
    wsd.avg_wind_speed
  FROM daily_complaint_proportions dcp
  JOIN wind_speed_data wsd
  ON dcp.complaint_date = wsd.date
)
SELECT
  complaint_type,
  ROUND(CORR(complaint_proportion, avg_wind_speed), 4) AS correlation_coefficient
FROM joined_data
GROUP BY complaint_type
ORDER BY correlation_coefficient DESC
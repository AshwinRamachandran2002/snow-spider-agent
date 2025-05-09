WITH complaint_data AS (
  SELECT
    DATE(created_date) AS complaint_date,
    LOWER(complaint_type) AS complaint_type,
    COUNT(*) AS complaint_count
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2008 AND 2017
    AND latitude IS NOT NULL AND longitude IS NOT NULL
    AND (
      ST_DWithin(ST_GeogPoint(longitude, latitude), ST_GeogPoint(-73.8726, 40.7772), 5000) OR
      ST_DWithin(ST_GeogPoint(longitude, latitude), ST_GeogPoint(-73.7781, 40.6413), 5000)
    )
  GROUP BY complaint_date, complaint_type
),
total_complaints_per_day AS (
  SELECT
    complaint_date,
    SUM(complaint_count) AS total_complaints
  FROM complaint_data
  GROUP BY complaint_date
),
complaint_percentage AS (
  SELECT
    c.complaint_date,
    c.complaint_type,
    c.complaint_count,
    c.complaint_count / t.total_complaints AS complaint_percentage
  FROM complaint_data c
  JOIN total_complaints_per_day t
    ON c.complaint_date = t.complaint_date
),
complaint_stats AS (
  SELECT
    complaint_type,
    SUM(complaint_count) AS total_complaint_count,
    COUNT(DISTINCT complaint_date) AS total_day_count
  FROM complaint_data
  GROUP BY complaint_type
),
common_complaints AS (
  SELECT
    complaint_type
  FROM complaint_stats
  WHERE total_complaint_count > 5000
),
temperature_data AS (
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, RIGHT('0'||mo,2), RIGHT('0'||da,2))) AS weather_date,
    temp
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2008' AND '2017'
    AND temp != 9999.9
    AND (
      (stn = '999999' AND wban = '14732') OR  -- LaGuardia
      (stn = '744860' AND wban = '94789')     -- JFK
    )
),
average_temperature_data AS (
  SELECT
    weather_date,
    AVG(temp) AS avg_temp
  FROM temperature_data
  GROUP BY weather_date
),
complaint_temperature AS (
  SELECT
    cp.complaint_date,
    cp.complaint_type,
    cp.complaint_count,
    cp.complaint_percentage,
    t.avg_temp
  FROM complaint_percentage cp
  JOIN average_temperature_data t
    ON cp.complaint_date = t.weather_date
),
correlation_data AS (
  SELECT
    ct.complaint_type,
    CORR(ct.complaint_count, ct.avg_temp) AS pearson_corr_count,
    CORR(ct.complaint_percentage, ct.avg_temp) AS pearson_corr_percentage
  FROM complaint_temperature ct
  WHERE ct.complaint_type IN (SELECT complaint_type FROM common_complaints)
  GROUP BY ct.complaint_type
),
final_data AS (
  SELECT
    cs.complaint_type,
    cs.total_complaint_count,
    cs.total_day_count,
    ROUND(cd.pearson_corr_count, 4) AS pearson_correlation_count,
    ROUND(cd.pearson_corr_percentage, 4) AS pearson_correlation_percentage
  FROM complaint_stats cs
  JOIN correlation_data cd
    ON cs.complaint_type = cd.complaint_type
  WHERE ABS(cd.pearson_corr_count) > 0.5 OR ABS(cd.pearson_corr_percentage) > 0.5
)
SELECT
  complaint_type,
  total_complaint_count,
  total_day_count,
  pearson_correlation_count,
  pearson_correlation_percentage
FROM final_data
ORDER BY complaint_type;
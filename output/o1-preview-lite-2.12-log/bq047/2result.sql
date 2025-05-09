WITH
  total_complaints AS (
    SELECT
      complaint_type,
      COUNT(*) AS total_count
    FROM `bigquery-public-data.new_york.311_service_requests`
    WHERE
      DATE(created_date) BETWEEN '2008-01-01' AND '2017-12-31' AND
      complaint_type IS NOT NULL
    GROUP BY complaint_type
    HAVING COUNT(*) > 5000
  ),
  daily_complaints AS (
    SELECT
      DATE(created_date) AS date,
      complaint_type,
      COUNT(*) AS daily_count
    FROM `bigquery-public-data.new_york.311_service_requests`
    WHERE
      DATE(created_date) BETWEEN '2008-01-01' AND '2017-12-31' AND
      complaint_type IS NOT NULL
    GROUP BY date, complaint_type
  ),
  daily_total_complaints AS (
    SELECT
      DATE(created_date) AS date,
      COUNT(*) AS total_daily_complaints
    FROM `bigquery-public-data.new_york.311_service_requests`
    WHERE DATE(created_date) BETWEEN '2008-01-01' AND '2017-12-31'
    GROUP BY date
  ),
  daily_percentage AS (
    SELECT
      dc.date,
      dc.complaint_type,
      dc.daily_count,
      dt.total_daily_complaints,
      CAST(dc.daily_count AS FLOAT64) / dt.total_daily_complaints AS daily_percentage
    FROM daily_complaints dc
    JOIN daily_total_complaints dt
    ON dc.date = dt.date
  ),
  temperature_data AS (
    SELECT
      PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0'))) AS date,
      CAST(temp AS FLOAT64) AS temp,
      stn
    FROM `bigquery-public-data.noaa_gsod.gsod*`
    WHERE
      _TABLE_SUFFIX BETWEEN '2008' AND '2017' AND
      stn IN ('725030', '744860') AND
      temp != 9999.9 AND temp IS NOT NULL
  ),
  average_daily_temp AS (
    SELECT
      date,
      AVG(temp) AS avg_temp
    FROM temperature_data
    GROUP BY date
  ),
  combined_data AS (
    SELECT
      dp.date,
      dp.complaint_type,
      dp.daily_count,
      dp.total_daily_complaints,
      dp.daily_percentage,
      adt.avg_temp
    FROM daily_percentage dp
    JOIN average_daily_temp adt
    ON dp.date = adt.date
    WHERE dp.complaint_type IN (SELECT complaint_type FROM total_complaints)
  ),
  complaint_correlations AS (
    SELECT
      cd.complaint_type,
      SUM(cd.daily_count) AS total_complaints,
      COUNT(cd.date) AS total_days_with_valid_temp_records,
      CORR(CAST(cd.daily_count AS FLOAT64), cd.avg_temp) AS corr_count_temp,
      CORR(cd.daily_percentage, cd.avg_temp) AS corr_percentage_temp
    FROM combined_data cd
    GROUP BY cd.complaint_type
  )
SELECT
  cc.complaint_type AS Complaint_Type,
  cc.total_complaints AS Total_Complaints,
  cc.total_days_with_valid_temp_records AS Total_Days_with_Valid_Temperature_Records,
  ROUND(cc.corr_count_temp, 4) AS Pearson_Correlation_Count_Temperature,
  ROUND(cc.corr_percentage_temp, 4) AS Pearson_Correlation_Percentage_Temperature
FROM complaint_correlations cc
WHERE
  ABS(cc.corr_count_temp) > 0.5 OR ABS(cc.corr_percentage_temp) > 0.5
ORDER BY ABS(cc.corr_percentage_temp) DESC, ABS(cc.corr_count_temp) DESC
;
WITH complaints AS (
  SELECT
    DATE(created_date) AS complaint_date,
    complaint_type,
    COUNT(*) AS daily_complaints
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE
    EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
    AND ST_DWithin(
      ST_GEOGPOINT(longitude, latitude),
      ST_GEOGPOINT(-73.7781, 40.6413), -- JFK Airport coordinates
      5000) -- 5 km radius in meters
    AND longitude IS NOT NULL
    AND latitude IS NOT NULL
  GROUP BY complaint_date, complaint_type
),
complaint_totals AS (
  SELECT complaint_type, SUM(daily_complaints) AS total_complaints
  FROM complaints
  GROUP BY complaint_type
  HAVING total_complaints > 3000
),
complaints_filtered AS (
  SELECT c.*
  FROM complaints c
  JOIN complaint_totals t ON c.complaint_type = t.complaint_type
),
wind AS (
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo, 2, '0'), LPAD(da, 2, '0'))) AS date,
    AVG(CAST(wdsp AS FLOAT64)) AS avg_wind_speed
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE
    _TABLE_SUFFIX BETWEEN '2011' AND '2020'
    AND stn = '744860'
    AND wban = '94789'
    AND CAST(wdsp AS FLOAT64) < 999.9
  GROUP BY date
),
complaints_with_wind AS (
  SELECT
    c.complaint_type,
    c.complaint_date,
    c.daily_complaints,
    w.avg_wind_speed
  FROM complaints_filtered c
  JOIN wind w ON c.complaint_date = w.date
)
SELECT
  complaint_type,
  ROUND(correlation, 4) AS correlation
FROM (
  SELECT
    complaint_type,
    CORR(daily_complaints, avg_wind_speed) AS correlation,
    ROW_NUMBER() OVER (ORDER BY CORR(daily_complaints, avg_wind_speed) DESC) AS rank_pos_corr,
    ROW_NUMBER() OVER (ORDER BY CORR(daily_complaints, avg_wind_speed) ASC) AS rank_neg_corr
  FROM complaints_with_wind
  GROUP BY complaint_type
)
WHERE rank_pos_corr = 1 OR rank_neg_corr = 1
ORDER BY correlation DESC;
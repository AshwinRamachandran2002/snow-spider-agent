WITH gsod_union AS (
  SELECT year, mo, da, stn, temp
  FROM (
        SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2008`
        UNION ALL SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2009`
        UNION ALL SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2010`
        UNION ALL SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2011`
        UNION ALL SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2012`
        UNION ALL SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2013`
        UNION ALL SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2014`
        UNION ALL SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2015`
        UNION ALL SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2016`
        UNION ALL SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2017`
       )
),
wx AS (
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0'))) AS obs_date,
    AVG(temp) AS mean_temp_f
  FROM gsod_union
  WHERE stn IN ('725030','744860')
    AND temp < 9999.9
  GROUP BY obs_date
),
daily_311 AS (
  SELECT
    DATE(created_date) AS req_date,
    complaint_type,
    COUNT(*)           AS daily_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY req_date, complaint_type
),
daily_totals AS (
  SELECT
    req_date,
    SUM(daily_cnt) AS total_daily_cnt
  FROM daily_311
  GROUP BY req_date
),
joined AS (
  SELECT
    d.complaint_type,
    d.req_date,
    d.daily_cnt,
    t.total_daily_cnt,
    w.mean_temp_f
  FROM daily_311 d
  JOIN daily_totals t ON d.req_date = t.req_date
  JOIN wx          w ON d.req_date = w.obs_date
)
SELECT
  complaint_type,
  SUM(daily_cnt)                         AS total_complaints,
  COUNT(DISTINCT req_date)               AS total_days,
  ROUND(CORR(daily_cnt, mean_temp_f),4)  AS pearson_temp_vs_count,
  ROUND(CORR(daily_cnt/total_daily_cnt, mean_temp_f),4) AS pearson_temp_vs_percentage
FROM joined
GROUP BY complaint_type
HAVING
  SUM(daily_cnt) > 5000
  AND ABS(CORR(daily_cnt, mean_temp_f)) > 0.5
ORDER BY ABS(pearson_temp_vs_count) DESC, complaint_type;
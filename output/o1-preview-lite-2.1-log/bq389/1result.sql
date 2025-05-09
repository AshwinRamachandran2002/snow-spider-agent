WITH

pm10 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month_num,
    AVG(arithmetic_mean) AS pm10_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_name = 'California' AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month_num
),

pm25_frm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month_num,
    AVG(arithmetic_mean) AS pm25_frm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_name = 'California' AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month_num
),

pm25_nonfrm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month_num,
    AVG(arithmetic_mean) AS pm25_nonfrm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_name = 'California' AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month_num
),

voc AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month_num,
    AVG(arithmetic_mean) AS voe_avg
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_name = 'California' AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month_num
),

so2 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month_num,
    AVG(arithmetic_mean * 10) AS so2_avg_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_name = 'California' AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month_num
),

lead AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month_num,
    AVG(arithmetic_mean * 100) AS lead_avg_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_name = 'California' AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month_num
),

months AS (
  SELECT 1 AS month_num, 'Jan' AS Month UNION ALL
  SELECT 2, 'Feb' UNION ALL
  SELECT 3, 'Mar' UNION ALL
  SELECT 4, 'Apr' UNION ALL
  SELECT 5, 'May' UNION ALL
  SELECT 6, 'Jun' UNION ALL
  SELECT 7, 'Jul' UNION ALL
  SELECT 8, 'Aug' UNION ALL
  SELECT 9, 'Sep' UNION ALL
  SELECT 10, 'Oct' UNION ALL
  SELECT 11, 'Nov' UNION ALL
  SELECT 12, 'Dec'
)

SELECT
  months.month_num AS Month_num,
  months.Month,
  ROUND(pm10.pm10_avg, 4) AS PM10_avg,
  ROUND(pm25_frm.pm25_frm_avg, 4) AS PM25_FRM_avg,
  ROUND(pm25_nonfrm.pm25_nonfrm_avg, 4) AS PM25_nonFRM_avg,
  ROUND(voc.voe_avg, 4) AS Volatile_Organic_Emissions_avg,
  ROUND(so2.so2_avg_scaled, 4) AS SO2_avg_scaled_by_10,
  ROUND(lead.lead_avg_scaled, 4) AS Lead_avg_scaled_by_100
FROM months
LEFT JOIN pm10 ON months.month_num = pm10.month_num
LEFT JOIN pm25_frm ON months.month_num = pm25_frm.month_num
LEFT JOIN pm25_nonfrm ON months.month_num = pm25_nonfrm.month_num
LEFT JOIN voc ON months.month_num = voc.month_num
LEFT JOIN so2 ON months.month_num = so2.month_num
LEFT JOIN lead ON months.month_num = lead.month_num
ORDER BY months.month_num;
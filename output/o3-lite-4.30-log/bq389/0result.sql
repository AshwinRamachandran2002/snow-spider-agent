WITH months AS (
  -- 12 calendar months of 2020
  SELECT FORMAT_DATE('%Y-%m', DATE_ADD(DATE '2020-01-01', INTERVAL n MONTH)) AS month
  FROM UNNEST(GENERATE_ARRAY(0, 11)) AS n
),
pm10 AS (
  SELECT
    FORMAT_DATE('%Y-%m', `date_local`) AS month,
    AVG(`arithmetic_mean`)             AS pm10_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),
pm25_frm AS (
  SELECT
    FORMAT_DATE('%Y-%m', `date_local`) AS month,
    AVG(`arithmetic_mean`)             AS pm25_frm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),
pm25_nonfrm AS (
  SELECT
    FORMAT_DATE('%Y-%m', `date_local`) AS month,
    AVG(`arithmetic_mean`)             AS pm25_nonfrm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),
voc AS (
  SELECT
    FORMAT_DATE('%Y-%m', `date_local`) AS month,
    AVG(`arithmetic_mean`)             AS voc_avg
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),
so2 AS (
  SELECT
    FORMAT_DATE('%Y-%m', `date_local`) AS month,
    AVG(`arithmetic_mean`) * 10.0      AS so2_scaled_avg
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),
lead AS (
  SELECT
    FORMAT_DATE('%Y-%m', `date_local`) AS month,
    AVG(`arithmetic_mean`) * 100.0     AS lead_scaled_avg
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
)

SELECT
  m.month,
  ROUND(p10.pm10_avg,         4) AS pm10_avg,
  ROUND(p25f.pm25_frm_avg,    4) AS pm25_frm_avg,
  ROUND(p25n.pm25_nonfrm_avg, 4) AS pm25_nonfrm_avg,
  ROUND(v.voc_avg,            4) AS voc_avg,
  ROUND(s.so2_scaled_avg,     4) AS so2_scaled_avg,
  ROUND(l.lead_scaled_avg,    4) AS lead_scaled_avg
FROM months AS m
LEFT JOIN pm10         AS p10 ON m.month = p10.month
LEFT JOIN pm25_frm     AS p25f ON m.month = p25f.month
LEFT JOIN pm25_nonfrm  AS p25n ON m.month = p25n.month
LEFT JOIN voc          AS v    ON m.month = v.month
LEFT JOIN so2          AS s    ON m.month = s.month
LEFT JOIN lead         AS l    ON m.month = l.month
ORDER BY m.month;
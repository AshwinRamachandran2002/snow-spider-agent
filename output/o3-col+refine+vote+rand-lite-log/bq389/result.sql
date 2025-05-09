-- Monthly average concentrations of major air-pollutants in California (2020)
WITH months AS (
  -- create the 12 calendar months of 2020
  SELECT FORMAT_DATE('%Y-%m', DATE_ADD(DATE '2020-01-01', INTERVAL m MONTH)) AS month
  FROM UNNEST(GENERATE_ARRAY(0, 11)) AS m
),

pm10 AS (
  SELECT FORMAT_DATE('%Y-%m', date_local) AS month,
         AVG(arithmetic_mean)            AS pm10_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

pm25_frm AS (
  SELECT FORMAT_DATE('%Y-%m', date_local) AS month,
         AVG(arithmetic_mean)            AS pm25_frm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

pm25_nonfrm AS (
  SELECT FORMAT_DATE('%Y-%m', date_local) AS month,
         AVG(arithmetic_mean)            AS pm25_nonfrm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

voc AS (
  SELECT FORMAT_DATE('%Y-%m', date_local) AS month,
         AVG(arithmetic_mean)            AS voc_avg
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

so2 AS (
  SELECT FORMAT_DATE('%Y-%m', date_local) AS month,
         10 * AVG(arithmetic_mean)       AS so2_avg_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

lead AS (
  SELECT FORMAT_DATE('%Y-%m', date_local) AS month,
         100 * AVG(arithmetic_mean)      AS lead_avg_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
)

SELECT
  m.month,
  p.pm10_avg,
  f.pm25_frm_avg,
  n.pm25_nonfrm_avg,
  v.voc_avg,
  s.so2_avg_scaled,
  l.lead_avg_scaled
FROM months            AS m
LEFT JOIN pm10         AS p USING (month)
LEFT JOIN pm25_frm     AS f USING (month)
LEFT JOIN pm25_nonfrm  AS n USING (month)
LEFT JOIN voc          AS v USING (month)
LEFT JOIN so2          AS s USING (month)
LEFT JOIN lead         AS l USING (month)
ORDER BY m.month;
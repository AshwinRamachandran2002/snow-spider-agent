WITH
-- 1) Monthly-average PM10 (µg/m³)
pm10 AS (
  SELECT
    FORMAT_DATE('%Y-%m', `date_local`) AS month,
    AVG(`arithmetic_mean`)            AS pm10
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),

-- 2) Monthly-average PM2.5 FRM (µg/m³)
pm25_frm AS (
  SELECT
    FORMAT_DATE('%Y-%m', `date_local`) AS month,
    AVG(`arithmetic_mean`)            AS pm25_frm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),

-- 3) Monthly-average PM2.5 non-FRM (µg/m³)
pm25_nonfrm AS (
  SELECT
    FORMAT_DATE('%Y-%m', `date_local`) AS month,
    AVG(`arithmetic_mean`)            AS pm25_nonfrm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),

-- 4) Monthly-average VOC (Sum of PAMS target compounds; ppb-C)
voc AS (
  SELECT
    FORMAT_DATE('%Y-%m', `date_local`) AS month,
    AVG(`arithmetic_mean`)            AS voc
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),

-- 5) Monthly-average SO₂ (ppb) scaled ×10
so2 AS (
  SELECT
    FORMAT_DATE('%Y-%m', `date_local`) AS month,
    10 * AVG(`arithmetic_mean`)       AS so2_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),

-- 6) Monthly-average Lead (µg/m³) scaled ×100
lead AS (
  SELECT
    FORMAT_DATE('%Y-%m', `date_local`) AS month,
    100 * AVG(`arithmetic_mean`)      AS lead_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
)

SELECT
  pm10.month,
  pm10.pm10,
  pm25_frm.pm25_frm,
  pm25_nonfrm.pm25_nonfrm,
  voc.voc,
  so2.so2_scaled,
  lead.lead_scaled
FROM pm10
LEFT JOIN pm25_frm   USING (month)
LEFT JOIN pm25_nonfrm USING (month)
LEFT JOIN voc         USING (month)
LEFT JOIN so2         USING (month)
LEFT JOIN lead        USING (month)
ORDER BY month;
WITH
-- Calendar months 1–12
months AS (
  SELECT m AS month
  FROM UNNEST(GENERATE_ARRAY(1, 12)) AS m
),

-- 1. PM10 daily averages
pm10 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)          AS pm10_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_code = '06'                  -- California
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

-- 2. PM2.5 – FRM daily averages
pm25_frm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)          AS pm25_frm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

-- 3. PM2.5 – non-FRM daily averages
pm25_nonfrm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)          AS pm25_nonfrm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

-- 4. VOC daily averages
voc AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)          AS voc_avg
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

-- 5. SO2 daily averages (scaled × 10)
so2 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean) * 10.0   AS so2_scaled_avg
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

-- 6. Lead daily averages (scaled × 100)
lead AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean) * 100.0  AS lead_scaled_avg
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
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
FROM months m
LEFT JOIN pm10        p10  ON m.month = p10.month
LEFT JOIN pm25_frm    p25f ON m.month = p25f.month
LEFT JOIN pm25_nonfrm p25n ON m.month = p25n.month
LEFT JOIN voc         v    ON m.month = v.month
LEFT JOIN so2         s    ON m.month = s.month
LEFT JOIN lead        l    ON m.month = l.month
ORDER BY m.month;
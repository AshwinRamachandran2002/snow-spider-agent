WITH
-- PM10 daily averages
pm10 AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`)         AS pm10_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_code = '06'                             -- California
    AND EXTRACT(YEAR  FROM `date_local`) = 2020
  GROUP BY month
),
-- PM2.5 (FRM) daily averages
pm25_frm AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`)           AS pm25_frm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),
-- PM2.5 (non‑FRM) daily averages
pm25_nonfrm AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`)           AS pm25_nonfrm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),
-- VOC daily averages
voc AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`)           AS voc_avg
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),
-- SO2 daily averages (scaled ×10)
so2 AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean` * 10)      AS so2_avg_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),
-- Lead daily averages (scaled ×100)
lead AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean` * 100)     AS lead_avg_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),
-- Collect all distinct months that appear in any sub‑result
months AS (
  SELECT month FROM pm10
  UNION DISTINCT SELECT month FROM pm25_frm
  UNION DISTINCT SELECT month FROM pm25_nonfrm
  UNION DISTINCT SELECT month FROM voc
  UNION DISTINCT SELECT month FROM so2
  UNION DISTINCT SELECT month FROM lead
)
SELECT
  m.month,
  pm10.pm10_avg,
  pm25_frm.pm25_frm_avg,
  pm25_nonfrm.pm25_nonfrm_avg,
  voc.voc_avg,
  so2.so2_avg_scaled,
  lead.lead_avg_scaled
FROM months AS m
LEFT JOIN pm10        USING (month)
LEFT JOIN pm25_frm    USING (month)
LEFT JOIN pm25_nonfrm USING (month)
LEFT JOIN voc         USING (month)
LEFT JOIN so2         USING (month)
LEFT JOIN lead        USING (month)
ORDER BY m.month;
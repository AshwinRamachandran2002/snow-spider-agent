/* Monthly‑average concentrations of key air pollutants in California – 2020 */
WITH months AS (
  SELECT m AS month
  FROM UNNEST(GENERATE_ARRAY(1,12)) AS m
),

-- PM10 (µg/m³, STP)
pm10 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)          AS avg_pm10
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_name = 'California'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

-- PM2.5 FRM/FEM (µg/m³, local conditions)
pm25_frm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)          AS avg_pm25_frm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_name = 'California'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

-- PM2.5 non‑FRM/FEM (µg/m³, local conditions)
pm25_nonfrm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)          AS avg_pm25_nonfrm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_name = 'California'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

-- Volatile organic compounds (ppbC)
voc AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)          AS avg_voc
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_name = 'California'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

-- SO₂ (ppb) – scaled × 10
so2 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    10 * AVG(arithmetic_mean)     AS avg_so2_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_name = 'California'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

-- Lead (µg/m³) – scaled × 100
lead AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    100 * AVG(arithmetic_mean)    AS avg_lead_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_name = 'California'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
)

SELECT
  m.month,
  pm10.avg_pm10,
  pm25_frm.avg_pm25_frm,
  pm25_nonfrm.avg_pm25_nonfrm,
  voc.avg_voc,
  so2.avg_so2_scaled,
  lead.avg_lead_scaled
FROM months AS m
LEFT JOIN pm10        USING (month)
LEFT JOIN pm25_frm    USING (month)
LEFT JOIN pm25_nonfrm USING (month)
LEFT JOIN voc         USING (month)
LEFT JOIN so2         USING (month)
LEFT JOIN lead        USING (month)
ORDER BY m.month;
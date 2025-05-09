/* Monthly average levels of selected pollutants in California (2020)  */
WITH
-- 1. PM10 -------------------------------------------------------------
pm10 AS (
  SELECT
    DATE_TRUNC(date_local, MONTH) AS month,
    AVG(arithmetic_mean)          AS pm10_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_code = '06'                          -- California
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

-- 2. PM2.5 – FRM ------------------------------------------------------
pm25_frm AS (
  SELECT
    DATE_TRUNC(date_local, MONTH) AS month,
    AVG(arithmetic_mean)          AS pm25_frm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

-- 3. PM2.5 – non‑FRM --------------------------------------------------
pm25_nonfrm AS (
  SELECT
    DATE_TRUNC(date_local, MONTH) AS month,
    AVG(arithmetic_mean)          AS pm25_nonfrm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

-- 4. VOC --------------------------------------------------------------
voc AS (
  SELECT
    DATE_TRUNC(date_local, MONTH) AS month,
    AVG(arithmetic_mean)          AS voc_avg
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

-- 5. SO2  (scaled ×10) -----------------------------------------------
so2 AS (
  SELECT
    DATE_TRUNC(date_local, MONTH) AS month,
    AVG(arithmetic_mean) * 10     AS so2_scaled_avg
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

-- 6. Lead (scaled ×100) ----------------------------------------------
lead AS (
  SELECT
    DATE_TRUNC(date_local, MONTH) AS month,
    AVG(arithmetic_mean) * 100    AS lead_scaled_avg
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

-- 7. Master list of months appearing in any sub‑result ---------------
all_months AS (
  SELECT month FROM pm10
  UNION DISTINCT SELECT month FROM pm25_frm
  UNION DISTINCT SELECT month FROM pm25_nonfrm
  UNION DISTINCT SELECT month FROM voc
  UNION DISTINCT SELECT month FROM so2
  UNION DISTINCT SELECT month FROM lead
)

-- 8. Combine everything ----------------------------------------------
SELECT
  m.month,
  pm10.pm10_avg,
  pm25_frm.pm25_frm_avg,
  pm25_nonfrm.pm25_nonfrm_avg,
  voc.voc_avg,
  so2.so2_scaled_avg,
  lead.lead_scaled_avg
FROM all_months m
LEFT JOIN pm10        USING (month)
LEFT JOIN pm25_frm    USING (month)
LEFT JOIN pm25_nonfrm USING (month)
LEFT JOIN voc         USING (month)
LEFT JOIN so2         USING (month)
LEFT JOIN lead        USING (month)
ORDER BY m.month;
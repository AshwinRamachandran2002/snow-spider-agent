/*  Monthly mean concentration of key pollutants in California (2020)
    – PM10
    – PM2.5 (FRM)
    – PM2.5 (non‑FRM)
    – VOC
    – SO2   (value ×10)
    – Lead  (value ×100)
*/
WITH
-- ---------- individual pollutant monthly averages -----------------
pm10 AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)           AS pm10_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_code = '06'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),
pm25_frm AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)           AS pm25_frm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_code = '06'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),
pm25_nonfrm AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)           AS pm25_nonfrm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_code = '06'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),
voc AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)           AS voc_avg
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_code = '06'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),
so2 AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)*10         AS so2_avg_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_code = '06'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),
lead AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)*100        AS lead_avg_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_code = '06'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

-- ---------- list of the 12 months of 2020 --------------------------
months AS (
  SELECT FORMAT_DATE('%Y-%m', DATE '2020-01-01' + INTERVAL m MONTH) AS month
  FROM UNNEST(GENERATE_ARRAY(0,11)) AS m
)

-- ---------- combine everything -------------------------------------
SELECT
  m.month,
  p10.pm10_avg,
  p25f.pm25_frm_avg,
  p25n.pm25_nonfrm_avg,
  v.voc_avg,
  s.so2_avg_scaled,
  l.lead_avg_scaled
FROM months            AS m
LEFT JOIN pm10         AS p10  ON m.month = p10.month
LEFT JOIN pm25_frm     AS p25f ON m.month = p25f.month
LEFT JOIN pm25_nonfrm  AS p25n ON m.month = p25n.month
LEFT JOIN voc          AS v    ON m.month = v.month
LEFT JOIN so2          AS s    ON m.month = s.month
LEFT JOIN lead         AS l    ON m.month = l.month
ORDER BY m.month;
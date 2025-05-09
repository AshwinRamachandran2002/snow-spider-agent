-- Monthly average concentrations of selected pollutants in California (2020)
WITH
/* ---------- PM10 (µg/m³) ---------- */
pm10 AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`)         AS avg_pm10
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_code = '06'                            -- California
    AND `date_local` BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

/* ---------- PM2.5 FRM (µg/m³) ---------- */
pm25_frm AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`)           AS avg_pm25_frm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_code = '06'
    AND `date_local` BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

/* ---------- PM2.5 non‑FRM (µg/m³) ---------- */
pm25_nonfrm AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`)           AS avg_pm25_nonfrm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_code = '06'
    AND `date_local` BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

/* ---------- Volatile Organic Compounds (VOC, ppb‑C) ---------- */
voc AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`)           AS avg_voc
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_code = '06'
    AND `date_local` BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

/* ---------- SO₂ (ppb)  – scale by 10 ---------- */
so2_scaled AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`) * 10      AS avg_so2_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_code = '06'
    AND `date_local` BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

/* ---------- Lead (µg/m³) – scale by 100 ---------- */
lead_scaled AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`) * 100     AS avg_lead_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_code = '06'
    AND `date_local` BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

/* ---------- Months present in any sub‑query ---------- */
months AS (
  SELECT month FROM pm10
  UNION DISTINCT SELECT month FROM pm25_frm
  UNION DISTINCT SELECT month FROM pm25_nonfrm
  UNION DISTINCT SELECT month FROM voc
  UNION DISTINCT SELECT month FROM so2_scaled
  UNION DISTINCT SELECT month FROM lead_scaled
)

SELECT
  m.month                                AS month,
  pm10.avg_pm10                          AS avg_pm10,
  pm25_frm.avg_pm25_frm                  AS avg_pm25_frm,
  pm25_nonfrm.avg_pm25_nonfrm            AS avg_pm25_nonfrm,
  voc.avg_voc                            AS avg_voc,
  so2_scaled.avg_so2_scaled              AS avg_so2_scaled,
  lead_scaled.avg_lead_scaled            AS avg_lead_scaled
FROM months           AS m
LEFT JOIN pm10        USING (month)
LEFT JOIN pm25_frm    USING (month)
LEFT JOIN pm25_nonfrm USING (month)
LEFT JOIN voc         USING (month)
LEFT JOIN so2_scaled  USING (month)
LEFT JOIN lead_scaled USING (month)
ORDER BY m.month;
/*  Monthly average (California – 2020) for
    PM10, PM2.5 FRM, PM2.5 non‑FRM, VOC, SO₂ (×10) and Lead (×100)
*/
WITH months AS (
  SELECT month
  FROM UNNEST(GENERATE_ARRAY(1,12)) AS month
),

-- PM10 24‑hour (STP)
pm10 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)            AS pm10
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_name = 'California'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

-- PM2.5 FRM/FEM 24‑hour
pm25_frm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)           AS pm25_frm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_name = 'California'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

-- PM2.5 non‑FRM/FEM 24‑hour
pm25_nonfrm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)           AS pm25_nonfrm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_name = 'California'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

-- Volatile Organic Compounds (all parameters) 24‑hour
voc AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)           AS voc
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_name = 'California'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

-- SO₂ 24‑hour ‑– scaled by 10
so2 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)*10        AS so2_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_name = 'California'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),

-- Lead 24‑hour – scaled by 100
lead AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)*100       AS lead_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_name = 'California'
    AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
)

SELECT
  m.month,
  ROUND(pm10.pm10,        4) AS pm10,
  ROUND(pf.pm25_frm,      4) AS pm25_frm,
  ROUND(pn.pm25_nonfrm,   4) AS pm25_nonfrm,
  ROUND(v.voc,            4) AS voc,
  ROUND(s.so2_scaled,     4) AS so2_scaled,
  ROUND(l.lead_scaled,    4) AS lead_scaled
FROM months AS m
LEFT JOIN pm10        AS pm10 ON m.month = pm10.month
LEFT JOIN pm25_frm    AS pf   ON m.month = pf.month
LEFT JOIN pm25_nonfrm AS pn   ON m.month = pn.month
LEFT JOIN voc         AS v    ON m.month = v.month
LEFT JOIN so2         AS s    ON m.month = s.month
LEFT JOIN lead        AS l    ON m.month = l.month
ORDER BY m.month;
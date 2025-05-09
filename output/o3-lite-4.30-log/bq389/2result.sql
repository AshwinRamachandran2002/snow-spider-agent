WITH months AS (
  SELECT m AS month
  FROM UNNEST(GENERATE_ARRAY(1, 12)) AS m
),
pm10 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)           AS pm10_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
pm25_frm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)           AS pm25_frm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
pm25_nonfrm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)           AS pm25_nonfrm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
voc AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)           AS voc_avg
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
so2 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)           AS so2_avg
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
lead AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)           AS lead_avg
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
)
SELECT
  m.month,
  ROUND(pm10.pm10_avg, 4)                AS pm10_avg,
  ROUND(pm25_frm.pm25_frm_avg, 4)        AS pm25_frm_avg,
  ROUND(pm25_nonfrm.pm25_nonfrm_avg, 4)  AS pm25_nonfrm_avg,
  ROUND(voc.voc_avg, 4)                  AS voc_avg,
  ROUND(so2.so2_avg * 10, 4)             AS so2_scaled_avg,
  ROUND(lead.lead_avg * 100, 4)          AS lead_scaled_avg
FROM months AS m
LEFT JOIN pm10        USING (month)
LEFT JOIN pm25_frm    USING (month)
LEFT JOIN pm25_nonfrm USING (month)
LEFT JOIN voc         USING (month)
LEFT JOIN so2         USING (month)
LEFT JOIN lead        USING (month)
ORDER BY m.month;
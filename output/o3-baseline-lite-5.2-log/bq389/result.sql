WITH months AS (
  SELECT m AS month
  FROM UNNEST(GENERATE_ARRAY(1,12)) AS m
),
pm10 AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`) AS pm10
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),
pm25_frm AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`) AS pm25_frm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),
pm25_nonfrm AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`) AS pm25_nonfrm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),
voc AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`) AS voc
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),
so2 AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    10 * AVG(`arithmetic_mean`) AS so2_scaled          -- scale SO2 by 10
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
),
lead AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    100 * AVG(`arithmetic_mean`) AS lead_scaled        -- scale Lead by 100
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE `state_name` = 'California'
    AND EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP BY month
)

SELECT
  m.month,
  ROUND(p10.pm10,          4) AS avg_pm10,
  ROUND(p25f.pm25_frm,     4) AS avg_pm25_frm,
  ROUND(p25n.pm25_nonfrm,  4) AS avg_pm25_nonfrm,
  ROUND(v.voc,             4) AS avg_voc,
  ROUND(s.so2_scaled,      4) AS avg_so2_scaled,
  ROUND(l.lead_scaled,     4) AS avg_lead_scaled
FROM months AS m
LEFT JOIN pm10         AS p10  ON m.month = p10.month
LEFT JOIN pm25_frm     AS p25f ON m.month = p25f.month
LEFT JOIN pm25_nonfrm  AS p25n ON m.month = p25n.month
LEFT JOIN voc          AS v    ON m.month = v.month
LEFT JOIN so2          AS s    ON m.month = s.month
LEFT JOIN lead         AS l    ON m.month = l.month
ORDER BY m.month;
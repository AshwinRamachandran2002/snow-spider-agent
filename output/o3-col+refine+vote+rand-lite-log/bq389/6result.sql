-- Monthly average concentrations of selected pollutants across California (2020)
WITH
pm10 AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local)        AS month,
    AVG(arithmetic_mean)                    AS pm10_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_code = '06'                      -- California
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
pm25_frm AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local)        AS month,
    AVG(arithmetic_mean)                    AS pm25_frm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
pm25_nonfrm AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local)        AS month,
    AVG(arithmetic_mean)                    AS pm25_nonfrm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
voc AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local)        AS month,
    AVG(arithmetic_mean)                    AS voc_avg
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
so2 AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local)        AS month,
    10 * AVG(arithmetic_mean)               AS so2_scaled_avg   -- scaled by 10
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
lead AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local)        AS month,
    100 * AVG(arithmetic_mean)              AS lead_scaled_avg  -- scaled by 100
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),

-- Collect all distinct months represented in any pollutant table
all_months AS (
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
  so2.so2_scaled_avg,
  lead.lead_scaled_avg
FROM all_months AS m
LEFT JOIN pm10        USING (month)
LEFT JOIN pm25_frm    USING (month)
LEFT JOIN pm25_nonfrm USING (month)
LEFT JOIN voc         USING (month)
LEFT JOIN so2         USING (month)
LEFT JOIN lead        USING (month)
ORDER BY m.month;
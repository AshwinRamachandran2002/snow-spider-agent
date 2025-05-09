WITH
-- monthly averages of each pollutant -------------------------------
pm10 AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)            AS avg_pm10
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_code = '06'                          -- California
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
pm25_frm AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)            AS avg_pm25_frm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
pm25_nonfrm AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)            AS avg_pm25_nonfrm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
voc AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)            AS avg_voc
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
so2 AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)*10         AS avg_so2_scaled   -- scale by 10
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
lead AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)*100        AS avg_lead_scaled  -- scale by 100
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
)

-- combine all pollutants -------------------------------------------
SELECT
  m.month,
  m.avg_pm10,
  f.avg_pm25_frm,
  n.avg_pm25_nonfrm,
  v.avg_voc,
  s.avg_so2_scaled,
  l.avg_lead_scaled
FROM pm10              AS m
LEFT JOIN pm25_frm     AS f USING (month)
LEFT JOIN pm25_nonfrm  AS n USING (month)
LEFT JOIN voc          AS v USING (month)
LEFT JOIN so2          AS s USING (month)
LEFT JOIN lead         AS l USING (month)
ORDER BY month;
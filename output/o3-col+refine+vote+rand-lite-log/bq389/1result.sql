-- Monthly average air–pollutant levels in California for 2020
WITH
pm10 AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`)          AS pm10_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE `state_code` = '06'
    AND `date_local` BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),
pm25_frm AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`)           AS pm25_frm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE `state_code` = '06'
    AND `date_local` BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),
pm25_nonfrm AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`)           AS pm25_nonfrm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE `state_code` = '06'
    AND `date_local` BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),
voc AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    AVG(`arithmetic_mean`)           AS voc_avg
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE `state_code` = '06'
    AND `date_local` BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),
so2 AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    10 * AVG(`arithmetic_mean`)      AS so2_scaled    -- scale ×10
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE `state_code` = '06'
    AND `date_local` BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
),
lead AS (
  SELECT
    EXTRACT(MONTH FROM `date_local`) AS month,
    100 * AVG(`arithmetic_mean`)     AS lead_scaled   -- scale ×100
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE `state_code` = '06'
    AND `date_local` BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY month
)
SELECT
  COALESCE(pm10.month, pm25_frm.month, pm25_nonfrm.month,
           voc.month, so2.month, lead.month)          AS month,
  pm10_avg,
  pm25_frm_avg,
  pm25_nonfrm_avg,
  voc_avg,
  so2_scaled,
  lead_scaled
FROM pm10
FULL JOIN pm25_frm    USING (month)
FULL JOIN pm25_nonfrm USING (month)
FULL JOIN voc         USING (month)
FULL JOIN so2         USING (month)
FULL JOIN lead        USING (month)
ORDER BY month;
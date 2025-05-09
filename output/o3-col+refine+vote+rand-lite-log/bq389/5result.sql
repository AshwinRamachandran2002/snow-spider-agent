-- Monthly average concentrations of selected pollutants in California – 2020
WITH
/* ---------- individual pollutants aggregated to monthly level ---------- */
pm10_monthly AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS mth,
    AVG(arithmetic_mean)          AS avg_pm10
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_name = 'California'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY mth
),

pm25_frm_monthly AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS mth,
    AVG(arithmetic_mean)          AS avg_pm25_frm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_name = 'California'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY mth
),

pm25_nonfrm_monthly AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS mth,
    AVG(arithmetic_mean)          AS avg_pm25_nonfrm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_name = 'California'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY mth
),

voc_monthly AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS mth,
    AVG(arithmetic_mean)          AS avg_voc
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_name = 'California'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY mth
),

so2_monthly AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS mth,
    /* scale SO2 by 10 as requested */
    10 * AVG(arithmetic_mean)      AS avg_so2_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_name = 'California'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY mth
),

lead_monthly AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS mth,
    /* scale Lead by 100 as requested */
    100 * AVG(arithmetic_mean)     AS avg_lead_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_name = 'California'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY mth
)

/* ---------- merge all pollutants ---------- */
SELECT
  mth                                         AS month,
  avg_pm10,
  avg_pm25_frm,
  avg_pm25_nonfrm,
  avg_voc,
  avg_so2_scaled,
  avg_lead_scaled
FROM pm10_monthly
FULL JOIN pm25_frm_monthly   USING (mth)
FULL JOIN pm25_nonfrm_monthly USING (mth)
FULL JOIN voc_monthly        USING (mth)
FULL JOIN so2_monthly        USING (mth)
FULL JOIN lead_monthly       USING (mth)
ORDER BY month;
WITH
-- 1. PM10 (µg/m³)
pm10 AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)            AS pm10
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_code = '06'                         -- California
    AND EXTRACT(YEAR FROM date_local) = 2020
    AND arithmetic_mean IS NOT NULL
  GROUP BY month
),

-- 2. PM2.5 – FRM/FEM (µg/m³)
pm25_frm AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)            AS pm25_frm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
    AND arithmetic_mean IS NOT NULL
  GROUP BY month
),

-- 3. PM2.5 – non‑FRM (µg/m³)
pm25_nonfrm AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)            AS pm25_nonfrm
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
    AND arithmetic_mean IS NOT NULL
  GROUP BY month
),

-- 4. VOCs – use “Sum of PAMS target compounds” (ppb‑C)
voc AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean)            AS voc
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
    AND parameter_code = 43000                 -- “Sum of PAMS target compounds”
    AND arithmetic_mean IS NOT NULL
  GROUP BY month
),

-- 5. SO2 (ppb)  – scale by 10
so2_scaled AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean) * 10        AS so2_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
    AND arithmetic_mean IS NOT NULL
  GROUP BY month
),

-- 6. Lead (µg/m³) – scale by 100
lead_scaled AS (
  SELECT
    FORMAT_DATE('%Y-%m', date_local) AS month,
    AVG(arithmetic_mean) * 100       AS lead_scaled
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
    AND arithmetic_mean IS NOT NULL
  GROUP BY month
),

-- Collect all distinct 2020 months appearing in any sub‑result
all_months AS (
  SELECT month FROM pm10
  UNION DISTINCT SELECT month FROM pm25_frm
  UNION DISTINCT SELECT month FROM pm25_nonfrm
  UNION DISTINCT SELECT month FROM voc
  UNION DISTINCT SELECT month FROM so2_scaled
  UNION DISTINCT SELECT month FROM lead_scaled
)

-- Final monthly table
SELECT
  m.month                                    AS month,
  pm10.pm10                                  AS avg_pm10,
  pm25_frm.pm25_frm                          AS avg_pm25_frm,
  pm25_nonfrm.pm25_nonfrm                    AS avg_pm25_nonfrm,
  voc.voc                                    AS avg_voc,
  so2_scaled.so2_scaled                      AS avg_so2_scaled,
  lead_scaled.lead_scaled                    AS avg_lead_scaled
FROM all_months AS m
LEFT JOIN pm10        USING (month)
LEFT JOIN pm25_frm    USING (month)
LEFT JOIN pm25_nonfrm USING (month)
LEFT JOIN voc         USING (month)
LEFT JOIN so2_scaled  USING (month)
LEFT JOIN lead_scaled USING (month)
ORDER BY month;
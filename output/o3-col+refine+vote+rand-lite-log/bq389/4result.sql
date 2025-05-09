-- Monthly average concentrations for selected pollutants in California – 2020
WITH months AS (
  SELECT m
  FROM UNNEST(GENERATE_ARRAY(1,12)) AS m
),

pm10 AS (
  SELECT EXTRACT(MONTH FROM `date_local`) AS m,
         AVG(`arithmetic_mean`)          AS pm10_avg
  FROM   `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE  `state_name` = 'California'
    AND  EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP  BY m
),

pm25_frm AS (
  SELECT EXTRACT(MONTH FROM `date_local`) AS m,
         AVG(`arithmetic_mean`)           AS pm25_frm_avg
  FROM   `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE  `state_name` = 'California'
    AND  EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP  BY m
),

pm25_nonfrm AS (
  SELECT EXTRACT(MONTH FROM `date_local`) AS m,
         AVG(`arithmetic_mean`)           AS pm25_nonfrm_avg
  FROM   `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE  `state_name` = 'California'
    AND  EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP  BY m
),

voc AS (
  SELECT EXTRACT(MONTH FROM `date_local`) AS m,
         AVG(`arithmetic_mean`)           AS voc_avg
  FROM   `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE  `state_name` = 'California'
    AND  EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP  BY m
),

so2 AS (
  SELECT EXTRACT(MONTH FROM `date_local`) AS m,
         AVG(`arithmetic_mean`) / 10      AS so2_avg_scaled   -- scale by 10
  FROM   `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE  `state_name` = 'California'
    AND  EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP  BY m
),

lead AS (
  SELECT EXTRACT(MONTH FROM `date_local`) AS m,
         AVG(`arithmetic_mean`) / 100     AS lead_avg_scaled  -- scale by 100
  FROM   `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE  `state_name` = 'California'
    AND  EXTRACT(YEAR FROM `date_local`) = 2020
  GROUP  BY m
)

SELECT  months.m                                            AS month,
        pm10.pm10_avg,
        pm25_frm.pm25_frm_avg,
        pm25_nonfrm.pm25_nonfrm_avg,
        voc.voc_avg,
        so2.so2_avg_scaled,
        lead.lead_avg_scaled
FROM    months
LEFT JOIN pm10        USING (m)
LEFT JOIN pm25_frm    USING (m)
LEFT JOIN pm25_nonfrm USING (m)
LEFT JOIN voc         USING (m)
LEFT JOIN so2         USING (m)
LEFT JOIN lead        USING (m)
ORDER BY month;
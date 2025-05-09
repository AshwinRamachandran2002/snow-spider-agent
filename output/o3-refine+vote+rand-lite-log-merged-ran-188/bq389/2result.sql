WITH
/*-------------------------------------------------
  Each CTE aggregates daily data to a statewide
  monthly mean for the specified pollutant.
-------------------------------------------------*/
pm10 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)          AS pm10_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_code = '06'                      -- California
    AND EXTRACT(YEAR  FROM date_local) = 2020  -- Year 2020
  GROUP BY month
),
pm25_frm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)          AS pm25_frm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
pm25_nonfrm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)          AS pm25_nonfrm_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
voc AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean)          AS voc_avg
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
so2 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean) * 10     AS so2_scaled_avg   -- scale by 10
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
),
lead AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS month,
    AVG(arithmetic_mean) * 100    AS lead_scaled_avg  -- scale by 100
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_code = '06'
    AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY month
)

/*-------------------------------------------------
  Combine the monthly results for all pollutants.
-------------------------------------------------*/
SELECT
  COALESCE(pm10.month,
           pm25_frm.month,
           pm25_nonfrm.month,
           voc.month,
           so2.month,
           lead.month)        AS month,
  pm10_avg,
  pm25_frm_avg,
  pm25_nonfrm_avg,
  voc_avg,
  so2_scaled_avg,
  lead_scaled_avg
FROM pm10
FULL OUTER JOIN pm25_frm     USING (month)
FULL OUTER JOIN pm25_nonfrm  USING (month)
FULL OUTER JOIN voc          USING (month)
FULL OUTER JOIN so2          USING (month)
FULL OUTER JOIN lead         USING (month)
ORDER BY month;
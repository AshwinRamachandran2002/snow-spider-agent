-- Task: Calculate the monthly average of the arithmetic mean concentrations of PM10, PM2.5 FRM, PM2.5 non-FRM, volatile organic emissions, SO₂ (scaled by a factor of 10), and Lead (scaled by a factor of 100) air pollutants measured in California during the year 2020. For each pollutant, extract the month from the date, group the data by month, compute the scaled averages where applicable, and present the results in a table with the month number, month name, and rounded average concentrations.

WITH months AS (
  SELECT 1 AS Month_num UNION ALL
  SELECT 2 UNION ALL
  SELECT 3 UNION ALL
  SELECT 4 UNION ALL
  SELECT 5 UNION ALL
  SELECT 6 UNION ALL
  SELECT 7 UNION ALL
  SELECT 8 UNION ALL
  SELECT 9 UNION ALL
  SELECT 10 UNION ALL
  SELECT 11 UNION ALL
  SELECT 12
),
pm10 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS Month_num,
    AVG(arithmetic_mean) AS PM10_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE state_name = 'California' AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY Month_num
),
pm25_frm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS Month_num,
    AVG(arithmetic_mean) AS PM25_FRM_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE state_name = 'California' AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY Month_num
),
pm25_nonfrm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS Month_num,
    AVG(arithmetic_mean) AS PM25_nonFRM_avg
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE state_name = 'California' AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY Month_num
),
voc AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS Month_num,
    AVG(arithmetic_mean) AS Volatile_Organic_Emissions_avg
  FROM `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE state_name = 'California' AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY Month_num
),
so2 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS Month_num,
    AVG(arithmetic_mean * 10) AS SO2_avg_scaled_by_10
  FROM `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE state_name = 'California' AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY Month_num
),
lead AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS Month_num,
    AVG(arithmetic_mean * 100) AS Lead_avg_scaled_by_100
  FROM `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE state_name = 'California' AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
  GROUP BY Month_num
)
SELECT
  months.Month_num,
  FORMAT_DATE('%b', DATE(2020, months.Month_num, 1)) AS Month,
  ROUND(pm10.PM10_avg, 4) AS PM10_avg,
  ROUND(pm25_frm.PM25_FRM_avg, 4) AS PM25_FRM_avg,
  ROUND(pm25_nonfrm.PM25_nonFRM_avg, 4) AS PM25_nonFRM_avg,
  ROUND(voc.Volatile_Organic_Emissions_avg, 4) AS Volatile_Organic_Emissions_avg,
  ROUND(so2.SO2_avg_scaled_by_10, 4) AS SO2_avg_scaled_by_10,
  ROUND(lead.Lead_avg_scaled_by_100, 4) AS Lead_avg_scaled_by_100
FROM months
LEFT JOIN pm10 USING (Month_num)
LEFT JOIN pm25_frm USING (Month_num)
LEFT JOIN pm25_nonfrm USING (Month_num)
LEFT JOIN voc USING (Month_num)
LEFT JOIN so2 USING (Month_num)
LEFT JOIN lead USING (Month_num)
ORDER BY months.Month_num
WITH pm10 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS Month_num,
    FORMAT_DATE('%b', date_local) AS Month,
    AVG(arithmetic_mean) AS PM10_avg
  FROM
    `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE
    state_code = '06' AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY
    Month_num, Month
),
pm25_frm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS Month_num,
    FORMAT_DATE('%b', date_local) AS Month,
    AVG(arithmetic_mean) AS PM25_FRM_avg
  FROM
    `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE
    state_code = '06' AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY
    Month_num, Month
),
pm25_nonfrm AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS Month_num,
    FORMAT_DATE('%b', date_local) AS Month,
    AVG(arithmetic_mean) AS PM25_nonFRM_avg
  FROM
    `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE
    state_code = '06' AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY
    Month_num, Month
),
voc AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS Month_num,
    FORMAT_DATE('%b', date_local) AS Month,
    AVG(arithmetic_mean) AS Volatile_Organic_Emissions_avg
  FROM
    `bigquery-public-data.epa_historical_air_quality.voc_daily_summary`
  WHERE
    state_code = '06' AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY
    Month_num, Month
),
so2 AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS Month_num,
    FORMAT_DATE('%b', date_local) AS Month,
    AVG(arithmetic_mean) * 10 AS SO2_avg_scaled_by_10
  FROM
    `bigquery-public-data.epa_historical_air_quality.so2_daily_summary`
  WHERE
    state_code = '06' AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY
    Month_num, Month
),
lead AS (
  SELECT
    EXTRACT(MONTH FROM date_local) AS Month_num,
    FORMAT_DATE('%b', date_local) AS Month,
    AVG(arithmetic_mean) * 100 AS Lead_avg_scaled_by_100
  FROM
    `bigquery-public-data.epa_historical_air_quality.lead_daily_summary`
  WHERE
    state_code = '06' AND EXTRACT(YEAR FROM date_local) = 2020
  GROUP BY
    Month_num, Month
)

SELECT
  all_months.Month_num,
  all_months.Month,
  ROUND(pm10.PM10_avg, 4) AS PM10_avg,
  ROUND(pm25_frm.PM25_FRM_avg, 4) AS PM25_FRM_avg,
  ROUND(pm25_nonfrm.PM25_nonFRM_avg, 4) AS PM25_nonFRM_avg,
  ROUND(voc.Volatile_Organic_Emissions_avg, 4) AS Volatile_Organic_Emissions_avg,
  ROUND(so2.SO2_avg_scaled_by_10, 4) AS SO2_avg_scaled_by_10,
  ROUND(lead.Lead_avg_scaled_by_100, 4) AS Lead_avg_scaled_by_100
FROM (
  SELECT DISTINCT Month_num, Month FROM pm10
  UNION DISTINCT
  SELECT DISTINCT Month_num, Month FROM pm25_frm
  UNION DISTINCT
  SELECT DISTINCT Month_num, Month FROM pm25_nonfrm
  UNION DISTINCT
  SELECT DISTINCT Month_num, Month FROM voc
  UNION DISTINCT
  SELECT DISTINCT Month_num, Month FROM so2
  UNION DISTINCT
  SELECT DISTINCT Month_num, Month FROM lead
) AS all_months
LEFT JOIN pm10 ON all_months.Month_num = pm10.Month_num AND all_months.Month = pm10.Month
LEFT JOIN pm25_frm ON all_months.Month_num = pm25_frm.Month_num AND all_months.Month = pm25_frm.Month
LEFT JOIN pm25_nonfrm ON all_months.Month_num = pm25_nonfrm.Month_num AND all_months.Month = pm25_nonfrm.Month
LEFT JOIN voc ON all_months.Month_num = voc.Month_num AND all_months.Month = voc.Month
LEFT JOIN so2 ON all_months.Month_num = so2.Month_num AND all_months.Month = so2.Month
LEFT JOIN lead ON all_months.Month_num = lead.Month_num AND all_months.Month = lead.Month
ORDER BY all_months.Month_num;
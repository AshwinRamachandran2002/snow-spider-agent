-- Task: Please calculate the monthly average levels of PM10 air pollutant in California for the year 2020.

SELECT
  EXTRACT(MONTH FROM date_local) AS Month_num,
  AVG(arithmetic_mean) AS PM10_avg
FROM `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
WHERE state_name = 'California' AND date_local BETWEEN '2020-01-01' AND '2020-12-31'
GROUP BY Month_num
ORDER BY Month_num
SELECT
  COALESCE(e.city_name, o.city) AS City,
  ROUND(o.avg_pm25 - e.avg_pm25, 4) AS PM2_5_Difference
FROM (
  SELECT
    city_name,
    ROUND(latitude, 2) AS lat_rounded,
    ROUND(longitude, 2) AS lon_rounded,
    AVG(arithmetic_mean) AS avg_pm25
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE parameter_name = 'PM2.5 - Local Conditions'
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
    AND EXTRACT(YEAR FROM date_local) = 1999
  GROUP BY city_name, lat_rounded, lon_rounded
) e
JOIN (
  SELECT
    city,
    ROUND(latitude, 2) AS lat_rounded,
    ROUND(longitude, 2) AS lon_rounded,
    AVG(value) AS avg_pm25
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM timestamp) = 2020
  GROUP BY city, lat_rounded, lon_rounded
) o
ON e.lat_rounded = o.lat_rounded
   AND e.lon_rounded = o.lon_rounded
WHERE o.avg_pm25 > e.avg_pm25
ORDER BY PM2_5_Difference DESC
LIMIT 3;
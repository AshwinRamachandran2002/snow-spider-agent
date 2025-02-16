-- Task: Find the three cities with the largest difference between their PM2.5 measurements from 1990 and 2020. For the 1990 data, use the EPA dataset (`bigquery-public-data.epa_historical_air_quality.air_quality_annual_summary`) and select 'arithmetic_mean' where 'units_of_measure' is 'Micrograms/cubic meter (LC)', 'parameter_name' is 'Acceptable PM2.5 AQI & Speciation Mass', and 'year' is 1990. For the 2020 data, use the OpenAQ dataset (`bigquery-public-data.openaq.global_air_quality`) and select 'value' where 'pollutant' is 'pm25' and the year extracted from 'timestamp' is 2020. Match the datasets by rounding their latitudes and longitudes to two decimal places. Calculate the difference between the EPA 'arithmetic_mean' and the OpenAQ 'value', and order the results from greatest to least difference. Return the city (from OpenAQ data), the EPA 'arithmetic_mean', the OpenAQ 'value', the 'timestamp', and the calculated difference for the top three cities.
SELECT
  aq.city,
  epa.arithmetic_mean,
  aq.value,
  aq.timestamp,
  (epa.arithmetic_mean - aq.value)
FROM
  `bigquery-public-data.openaq.global_air_quality` AS aq
JOIN
  `bigquery-public-data.epa_historical_air_quality.air_quality_annual_summary` AS epa
ON
  ROUND(aq.latitude, 2) = ROUND(epa.latitude, 2)
  AND ROUND(aq.longitude, 2) = ROUND(epa.longitude, 2)
WHERE
  epa.units_of_measure = "Micrograms/cubic meter (LC)"
  AND epa.parameter_name = "Acceptable PM2.5 AQI & Speciation Mass"
  AND epa.year = 1990
  AND aq.pollutant = "pm25"
  AND EXTRACT(YEAR FROM aq.timestamp) = 2020
ORDER BY
  (epa.arithmetic_mean - aq.value) DESC
LIMIT 3
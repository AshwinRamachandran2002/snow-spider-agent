-- Task: Find the top 3 cities with the highest PM2.5 measurements from the OpenAQ dataset in 2020 where pollutant = 'pm25', ordered from highest to lowest value.
SELECT
  aq.city,
  aq.value,
  aq.timestamp
FROM
  `bigquery-public-data.openaq.global_air_quality` AS aq
WHERE
  aq.pollutant = "pm25"
  AND EXTRACT(YEAR FROM aq.timestamp) = 2020
ORDER BY
  aq.value DESC
LIMIT 3
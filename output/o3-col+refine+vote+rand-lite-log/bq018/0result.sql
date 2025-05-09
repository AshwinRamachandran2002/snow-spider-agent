-- Day in March/April with the highest COVID-19 confirmed-case growth rate in the U.S.
SELECT
  FORMAT_DATE('%m-%d', date) AS mm_dd
FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE location_key = 'US'
  AND EXTRACT(MONTH FROM date) IN (3, 4)
ORDER BY SAFE_DIVIDE(new_confirmed,
                     cumulative_confirmed - new_confirmed) DESC
LIMIT 1;
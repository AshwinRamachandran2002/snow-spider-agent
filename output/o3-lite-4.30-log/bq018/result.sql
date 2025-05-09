SELECT
  FORMAT_DATE('%m-%d', date) AS day
FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE country_code = 'US'
  AND aggregation_level = 0
  AND EXTRACT(MONTH FROM date) IN (3, 4)
ORDER BY SAFE_DIVIDE(new_confirmed,
                     NULLIF(cumulative_confirmed - new_confirmed, 0)) DESC,
         date
LIMIT 1;
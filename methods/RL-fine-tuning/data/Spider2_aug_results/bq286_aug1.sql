-- Task: For each female baby name in 2021, compute the total number of babies with that name across all states, showing only the top 100 results.

SELECT
  name,
  SUM(number) AS total_number
FROM
  `bigquery-public-data.usa_names.usa_1910_current`
WHERE
  gender = 'F' AND
  year = 2021
GROUP BY
  name
ORDER BY
  total_number DESC
LIMIT 100
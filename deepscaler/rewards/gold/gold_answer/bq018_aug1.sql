-- Task: Which day in March and April had the highest increase in cumulative confirmed COVID-19 cases in the United States? The format is MM-DD.
WITH daily_data AS (
  SELECT
    date,
    MAX(cumulative_confirmed) AS cumulative_confirmed
  FROM
    `bigquery-public-data`.`covid19_open_data`.`covid19_open_data`
  WHERE
    country_code = 'US'
    AND date BETWEEN '2020-03-01' AND '2020-04-30'
    AND aggregation_level = 0
    AND cumulative_confirmed IS NOT NULL
  GROUP BY
    date
)
SELECT
  FORMAT_DATE('%m-%d', date) AS Date,
  cumulative_confirmed - LAG(cumulative_confirmed) OVER (ORDER BY date) AS Daily_Increase
FROM
  daily_data
QUALIFY
  LAG(cumulative_confirmed) OVER (ORDER BY date) IS NOT NULL
ORDER BY
  Daily_Increase DESC
LIMIT
  1
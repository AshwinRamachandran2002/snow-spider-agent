-- Task: Find the date between March 1st and April 30th, 2020, that had the highest daily percentage increase in cumulative COVID-19 confirmed cases in the United States at the country level (aggregation_level = 0). Return the date in MM-DD format.
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
  ROUND(
    ((cumulative_confirmed - LAG(cumulative_confirmed) OVER (ORDER BY date)) / NULLIF(LAG(cumulative_confirmed) OVER (ORDER BY date), 0)) * 100,
    4
  ) AS Confirmed_Case_Growth_Rate
FROM
  daily_data
QUALIFY
  LAG(cumulative_confirmed) OVER (ORDER BY date) IS NOT NULL
ORDER BY
  Confirmed_Case_Growth_Rate DESC
LIMIT
  1
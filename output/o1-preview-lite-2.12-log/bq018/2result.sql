SELECT
  FORMAT_DATE('%m-%d', date) AS Date,
  ROUND(SAFE_DIVIDE(cumulative_confirmed - previous_cumulative, previous_cumulative) * 100, 4) AS Confirmed_Case_Growth_Rate
FROM (
  SELECT
    date,
    cumulative_confirmed,
    LAG(cumulative_confirmed) OVER (ORDER BY date) AS previous_cumulative
  FROM
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    country_code = 'US'
    AND aggregation_level = 0
    AND cumulative_confirmed IS NOT NULL
    AND date BETWEEN '2020-03-01' AND '2020-04-30'
  ORDER BY
    date
)
WHERE
  previous_cumulative IS NOT NULL
  AND previous_cumulative > 0
ORDER BY
  Confirmed_Case_Growth_Rate DESC
LIMIT 1;
WITH us_data AS (
  SELECT
    `date`,
    `new_confirmed`,
    `cumulative_confirmed`
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE `location_key` = 'US'
    AND EXTRACT(MONTH FROM `date`) IN (3, 4)          -- March and April
),
growth_rates AS (
  SELECT
    `date`,
    SAFE_DIVIDE(`new_confirmed`,
                LAG(`cumulative_confirmed`) OVER (ORDER BY `date`)) AS growth_rate
  FROM us_data
)
SELECT
  FORMAT_DATE('%m-%d', `date`) AS fastest_growth_day
FROM growth_rates
WHERE growth_rate IS NOT NULL
ORDER BY growth_rate DESC, `date`
LIMIT 1;
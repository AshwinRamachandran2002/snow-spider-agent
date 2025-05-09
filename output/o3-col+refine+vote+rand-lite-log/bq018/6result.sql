-- Day in March / April with the highest COVID-19 confirmed-case growth rate (U-S, national level)
WITH daily_us AS (
  SELECT
    `date`,
    SUM(`new_confirmed`)        AS new_confirmed,
    SUM(`cumulative_confirmed`) AS cumulative_confirmed
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE `country_code` = 'US'
    AND `aggregation_level` = 0          -- national level
    AND EXTRACT(MONTH FROM `date`) IN (3,4)   -- March or April
  GROUP BY `date`
),
growth AS (
  SELECT
    `date`,
    new_confirmed,
    cumulative_confirmed,
    SAFE_DIVIDE(new_confirmed,
                LAG(cumulative_confirmed) OVER (ORDER BY `date`)) AS growth_ratio
  FROM daily_us
)
SELECT
  FORMAT_DATE('%m-%d', `date`) AS highest_growth_day
FROM growth
ORDER BY growth_ratio DESC
LIMIT 1;
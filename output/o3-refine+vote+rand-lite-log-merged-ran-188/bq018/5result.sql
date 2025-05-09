-- Day in March–April 2020 with the highest confirmed–case growth rate in the U.S.
WITH us_daily AS (
  SELECT
    `date`,
    new_confirmed,
    cumulative_confirmed,
    SAFE_DIVIDE(new_confirmed, cumulative_confirmed - new_confirmed) AS growth_rate
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE location_key = 'US'            -- United States (country‑level row)
    AND aggregation_level = 0          -- Country aggregation
    AND `date` BETWEEN '2020-03-01' AND '2020-04-30'
    AND cumulative_confirmed - new_confirmed > 0   -- avoid divide‑by‑zero
)
SELECT
  FORMAT_DATE('%m-%d', `date`) AS highest_growth_day
FROM us_daily
ORDER BY growth_rate DESC
LIMIT 1;
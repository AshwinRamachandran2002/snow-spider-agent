-- Which day in March & April had the highest daily confirmed-case growth-rate in the U.S.?
SELECT
  FORMAT_DATE('%m-%d', date) AS highest_growth_mm_dd
FROM (
  SELECT
    date,
    SAFE_DIVIDE(new_confirmed,
                LAG(cumulative_confirmed) OVER (ORDER BY date)) AS growth_rate
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE location_key = 'US'                      -- United States, national level
)
WHERE EXTRACT(MONTH FROM date) IN (3, 4)         -- March or April (any year)
ORDER BY growth_rate DESC                        -- highest growth-rate first
LIMIT 1;                                         -- return the single top day
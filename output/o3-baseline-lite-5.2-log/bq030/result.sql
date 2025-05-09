SELECT
  country_name,
  ROUND(cumulative_recovered / cumulative_confirmed * 100, 4) AS recovery_rate_percentage
FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
WHERE
  date = '2020-05-10'
  AND aggregation_level = 0            -- country‑level rows only
  AND cumulative_confirmed >= 50000    -- countries with > 50,000 confirmed cases
  AND cumulative_recovered IS NOT NULL -- ensure a recovery count is present
ORDER BY
  recovery_rate_percentage DESC
LIMIT 3;
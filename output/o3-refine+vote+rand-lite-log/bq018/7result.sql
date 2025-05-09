WITH us_daily AS (
  SELECT
    `date`,
    new_confirmed,
    cumulative_confirmed,
    -- growth rate = (new cases) / (cases up to previous day)
    SAFE_DIVIDE(
      CAST(new_confirmed AS FLOAT64),
      NULLIF(cumulative_confirmed - new_confirmed, 0)
    ) AS growth_rate
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE location_key = 'US'               -- United States, country level
    AND EXTRACT(MONTH FROM `date`) IN (3,4)  -- March or April (any year)
)

SELECT
  FORMAT_DATE('%m-%d', `date`) AS day_mm_dd
FROM us_daily
WHERE growth_rate IS NOT NULL
ORDER BY growth_rate DESC
LIMIT 1;
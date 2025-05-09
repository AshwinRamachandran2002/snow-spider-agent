-- Top three recovery rates (as of 2020‑05‑10) among countries with >50,000 confirmed cases
WITH country_status AS (
  SELECT
    country_name,
    cumulative_confirmed,
    cumulative_recovered,
    -- compute recovery rate as percentage
    (cumulative_recovered / cumulative_confirmed) * 100 AS recovery_rate_pct
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE
    date = '2020-05-10'
    AND aggregation_level = 0            -- country‑level rows only
    AND cumulative_confirmed > 50000     -- at least 50,000 confirmed cases
    AND cumulative_recovered IS NOT NULL -- avoid division by NULL
)

SELECT
  country_name,
  ROUND(recovery_rate_pct, 4) AS recovery_rate_percentage
FROM country_status
ORDER BY
  recovery_rate_pct DESC,
  country_name
LIMIT 3;
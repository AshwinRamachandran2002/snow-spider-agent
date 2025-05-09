-- Which month in 2017 had the largest absolute difference between
-- cumulative bike-usage minutes (in thousands) for Customers and Subscribers?
WITH monthly_usage AS (
  SELECT
    EXTRACT(MONTH FROM end_date) AS month,
    -- total minutes (in thousands) ridden by Customers
    SUM(CASE WHEN LOWER(subscriber_type) = 'customer'
             THEN duration_sec END) / 60.0 / 1000 AS customer_minutes_k,
    -- total minutes (in thousands) ridden by Subscribers
    SUM(CASE WHEN LOWER(subscriber_type) = 'subscriber'
             THEN duration_sec END) / 60.0 / 1000 AS subscriber_minutes_k
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM end_date) = 2017
  GROUP BY month
)
SELECT
  month
FROM monthly_usage
ORDER BY ABS(subscriber_minutes_k - customer_minutes_k) DESC
LIMIT 1;
-- Month (number) in 2017 with the largest absolute gap between
-- cumulative bike-usage minutes (in thousands) for Customers vs Subscribers
WITH month_totals AS (
  SELECT
    EXTRACT(MONTH FROM end_date)                                    AS month_num,
    SUM(CASE WHEN subscriber_type = 'Customer'   THEN duration_sec END)/60/1000 AS customer_k_min,
    SUM(CASE WHEN subscriber_type = 'Subscriber' THEN duration_sec END)/60/1000 AS subscriber_k_min
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM end_date) = 2017
  GROUP BY month_num
)
SELECT month_num
FROM month_totals
ORDER BY ABS(subscriber_k_min - customer_k_min) DESC
LIMIT 1;
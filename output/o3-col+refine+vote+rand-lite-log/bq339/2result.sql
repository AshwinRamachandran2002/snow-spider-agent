WITH monthly AS (
  -- total riding minutes per rider class for each 2017 month
  SELECT
    EXTRACT(MONTH FROM end_date) AS month,
    SUM(IF(subscriber_type = 'Customer',   duration_sec, 0)) / 60.0 AS customer_min,
    SUM(IF(subscriber_type = 'Subscriber', duration_sec, 0)) / 60.0 AS subscriber_min
  FROM
    `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE
    EXTRACT(YEAR FROM end_date) = 2017
  GROUP BY
    month
),
ranked AS (
  -- convert to thousands of minutes and rank by absolute difference
  SELECT
    month,
    ROUND(customer_min   / 1000.0, 2) AS customer_kmins,
    ROUND(subscriber_min / 1000.0, 2) AS subscriber_kmins,
    ROUND(ABS(customer_min - subscriber_min) / 1000.0, 2) AS difference_kmins,
    ROW_NUMBER() OVER (ORDER BY ABS(customer_min - subscriber_min) DESC) AS rnk
  FROM
    monthly
)
-- month with the largest customer-vs-subscriber gap
SELECT
  month AS month_number,
  customer_kmins,
  subscriber_kmins,
  difference_kmins
FROM
  ranked
WHERE
  rnk = 1;
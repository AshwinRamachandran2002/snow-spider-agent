WITH monthly_minutes AS (
  SELECT
    EXTRACT(MONTH FROM end_date) AS month_num,
    subscriber_type,
    SUM(duration_sec) / 60.0 AS tot_minutes          -- convert seconds → minutes
  FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
  WHERE EXTRACT(YEAR FROM end_date) = 2017            -- only 2017 trips
  GROUP BY month_num, subscriber_type
),
monthly_gap AS (
  SELECT
    month_num,
    ABS(SUM(CASE WHEN subscriber_type = 'Customer'   THEN tot_minutes END) -
        SUM(CASE WHEN subscriber_type = 'Subscriber' THEN tot_minutes END)
    ) AS abs_diff_min                                 -- absolute gap in minutes
  FROM monthly_minutes
  GROUP BY month_num
)
SELECT
  month_num,                                          -- month (1–12)
  ROUND(abs_diff_min / 1000, 2) AS abs_diff_thousand_minutes
FROM monthly_gap
ORDER BY abs_diff_min DESC
LIMIT 1;
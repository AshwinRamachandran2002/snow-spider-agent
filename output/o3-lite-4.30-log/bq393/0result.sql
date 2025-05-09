WITH activity AS (
  SELECT
    `by`                                        AS user_id,
    DATE_TRUNC(CAST(`timestamp` AS DATE), MONTH) AS month_bucket
  FROM `bigquery-public-data.hacker_news.full`
  WHERE `timestamp` <= '2024-09-10'
    AND `by` IS NOT NULL
),
extremes AS (
  SELECT
    user_id,
    MIN(month_bucket) AS first_month,
    MAX(month_bucket) AS last_month
  FROM activity
  GROUP BY user_id
),
month_series AS (
  SELECT
    e.user_id,
    mth AS month_bucket,
    DATE_DIFF(mth, e.first_month, MONTH) AS month_number
  FROM extremes AS e
  CROSS JOIN UNNEST(GENERATE_DATE_ARRAY(e.first_month,
                                        e.last_month,
                                        INTERVAL 1 MONTH)) AS mth
),
missing AS (
  SELECT
    ms.user_id,
    ms.month_number
  FROM month_series AS ms
  LEFT JOIN activity AS a
         ON a.user_id = ms.user_id
        AND a.month_bucket = ms.month_bucket
  WHERE a.month_bucket IS NULL
),
ranked AS (
  SELECT
    user_id,
    MAX(month_number) AS highest_missing_month
  FROM missing
  GROUP BY user_id
)
SELECT
  user_id,
  highest_missing_month AS month_number
FROM ranked
ORDER BY highest_missing_month DESC, user_id
LIMIT 1;
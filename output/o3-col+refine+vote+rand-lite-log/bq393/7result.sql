-- user with the highest month index who had internal gaps and then became inactive
WITH per_user AS (
  SELECT
    `by` AS user_id,
    MIN(DATE_TRUNC(DATE(`timestamp`), MONTH)) AS first_month,
    MAX(DATE_TRUNC(DATE(`timestamp`), MONTH)) AS last_month,
    COUNT(DISTINCT DATE_TRUNC(DATE(`timestamp`), MONTH))        AS active_months,
    DATE_DIFF(
      MAX(DATE_TRUNC(DATE(`timestamp`), MONTH)),
      MIN(DATE_TRUNC(DATE(`timestamp`), MONTH)),
      MONTH
    ) + 1                                                      AS month_number      -- months since first activity
  FROM `bigquery-public-data.hacker_news.full`
  WHERE `by` IS NOT NULL
    AND `timestamp` < '2024-09-10'
  GROUP BY user_id
),
filtered AS (
  SELECT *
  FROM per_user
  WHERE month_number > active_months        -- at least one missing month inside span
    AND last_month < DATE '2024-09-01'      -- no activity after last_month (inactive thereafter)
)
SELECT user_id, month_number
FROM (
  SELECT
    user_id,
    month_number,
    RANK() OVER (ORDER BY month_number DESC) AS rnk
  FROM filtered
)
WHERE rnk = 1;
WITH
users_7day AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'
    AND EXISTS (
      SELECT 1
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'engagement_time_msec'
        AND ep.value.int_value > 0
    )
),
users_2day AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20210106' AND '20210107'
    AND EXISTS (
      SELECT 1
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'engagement_time_msec'
        AND ep.value.int_value > 0
    )
)
SELECT
  COUNT(*) AS distinct_users_with_7day_positive_but_not_2day
FROM users_7day
WHERE user_pseudo_id NOT IN (SELECT user_pseudo_id FROM users_2day);
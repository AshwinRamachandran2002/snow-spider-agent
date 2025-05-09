/* distinct_pseudo_users */
WITH seven_day AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'
    AND event_name = 'user_engagement'
    AND EXISTS (
      SELECT 1
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'engagement_time_msec'
        AND ep.value.int_value > 0
    )
),
two_day AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20210106' AND '20210107'
    AND event_name = 'user_engagement'
    AND EXISTS (
      SELECT 1
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'engagement_time_msec'
        AND ep.value.int_value > 0
    )
)
SELECT COUNT(*) AS distinct_pseudo_users
FROM seven_day
LEFT JOIN two_day USING (user_pseudo_id)
WHERE two_day.user_pseudo_id IS NULL;
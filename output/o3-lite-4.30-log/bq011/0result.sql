WITH seven_day_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'
    AND e.event_name = 'user_engagement'
    AND EXISTS (
      SELECT 1
      FROM UNNEST(e.event_params) AS ep
      WHERE ep.key = 'engagement_time_msec'
        AND ep.value.int_value > 0
    )
    AND user_pseudo_id IS NOT NULL
),
two_day_users AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS e
  WHERE _TABLE_SUFFIX BETWEEN '20210106' AND '20210107'
    AND e.event_name = 'user_engagement'
    AND EXISTS (
      SELECT 1
      FROM UNNEST(e.event_params) AS ep
      WHERE ep.key = 'engagement_time_msec'
        AND ep.value.int_value > 0
    )
    AND user_pseudo_id IS NOT NULL
)
SELECT COUNT(*) AS distinct_pseudo_users
FROM seven_day_users s
LEFT JOIN two_day_users t
ON s.user_pseudo_id = t.user_pseudo_id
WHERE t.user_pseudo_id IS NULL;
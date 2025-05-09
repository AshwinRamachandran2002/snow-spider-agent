WITH seven_day AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'      -- 7-day window
    AND ep.key = 'engagement_time_msec'
    AND ep.value.int_value > 0                               -- positive engagement
),
two_day AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20210106' AND '20210107'      -- 2-day window
    AND ep.key = 'engagement_time_msec'
    AND ep.value.int_value > 0
)
SELECT COUNT(*) AS distinct_users_7d_positive_no_2d_positive
FROM   seven_day
WHERE  user_pseudo_id NOT IN (SELECT user_pseudo_id FROM two_day);
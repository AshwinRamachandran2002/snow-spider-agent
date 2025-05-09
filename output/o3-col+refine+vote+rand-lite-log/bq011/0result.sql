WITH seven_day AS (
  -- users with positive engagement_time_msec between 2021-01-01 and 2021-01-07 (inclusive)
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021010*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'
    AND event_name = 'user_engagement'
    AND ep.key  = 'engagement_time_msec'
    AND ep.value.int_value > 0
),
two_day AS (
  -- users with positive engagement_time_msec on 2021-01-06 or 2021-01-07
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021010*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20210106' AND '20210107'
    AND event_name = 'user_engagement'
    AND ep.key  = 'engagement_time_msec'
    AND ep.value.int_value > 0
)
SELECT COUNT(*) AS users_positive_7d_no_positive_2d
FROM seven_day
WHERE user_pseudo_id NOT IN (SELECT user_pseudo_id FROM two_day);
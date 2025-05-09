-- Count users with positive engagement in 1-7 Jan 2021
-- but NOT in 6-7 Jan 2021
WITH seven_day AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021010*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'
    AND ep.key = 'engagement_time_msec'
    AND ep.value.int_value > 0
),
two_day AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021010*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX IN ('20210106','20210107')
    AND ep.key = 'engagement_time_msec'
    AND ep.value.int_value > 0
)
SELECT COUNT(*) AS distinct_users_without_recent_engagement
FROM seven_day
WHERE user_pseudo_id NOT IN (SELECT user_pseudo_id FROM two_day);
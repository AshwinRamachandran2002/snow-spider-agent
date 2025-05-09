WITH seven_day AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'          -- 7-day window (inclusive)
    AND ep.key = 'engagement_time_msec'
    AND ep.value.int_value > 0                                   -- positive engagement
),
two_day AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20210106' AND '20210107'          -- 2-day window (inclusive)
    AND ep.key = 'engagement_time_msec'
    AND ep.value.int_value > 0
)
SELECT COUNT(*) AS distinct_pseudo_users
FROM (
  SELECT user_pseudo_id FROM seven_day
  EXCEPT DISTINCT
  SELECT user_pseudo_id FROM two_day
);
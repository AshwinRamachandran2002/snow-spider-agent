-- Task: How many pseudo users were active in the last 7 days as of January 7, 2021?
SELECT
  COUNT(DISTINCT user_pseudo_id) AS active_users_count
FROM
  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS T
CROSS JOIN
  UNNEST(T.event_params) AS event_params
WHERE
  event_params.key = 'engagement_time_msec' AND event_params.value.int_value > 0
  /* Has engaged in last 7 days */
  AND event_timestamp > UNIX_MICROS(TIMESTAMP_SUB(TIMESTAMP('2021-01-07 23:59:59'), INTERVAL 7 DAY))
  /* Include only relevant tables based on the fixed timestamp */
  AND _TABLE_SUFFIX BETWEEN '20210101' AND '20210107';
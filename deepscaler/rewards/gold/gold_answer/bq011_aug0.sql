-- Task: Calculate the number of unique pseudo users (`user_pseudo_id`) who had events with `'engagement_time_msec' > 0` between January 1, 2021 and January 7, 2021 (last 7 days), but did not have any such events between January 6, 2021 and January 7, 2021 (last 2 days), using data from the `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` tables.
SELECT
  COUNT(DISTINCT MDaysUsers.user_pseudo_id) AS n_day_inactive_users_count
FROM
  (
    SELECT
      user_pseudo_id
    FROM
      `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS T
    CROSS JOIN
      UNNEST(T.event_params) AS event_params
    WHERE
      event_params.key = 'engagement_time_msec' AND event_params.value.int_value > 0
      /* Has engaged in last M = 7 days */
      AND event_timestamp > UNIX_MICROS(TIMESTAMP_SUB(TIMESTAMP('2021-01-07 23:59:59'), INTERVAL 7 DAY))
      /* Include only relevant tables based on the fixed timestamp */
      AND _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'
  ) AS MDaysUsers
LEFT JOIN
  (
    SELECT
      user_pseudo_id
    FROM
      `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS T
    CROSS JOIN
      UNNEST(T.event_params) AS event_params
    WHERE
      event_params.key = 'engagement_time_msec' AND event_params.value.int_value > 0
      /* Has engaged in last N = 2 days */
      AND event_timestamp > UNIX_MICROS(TIMESTAMP_SUB(TIMESTAMP('2021-01-07 23:59:59'), INTERVAL 2 DAY))
      /* Include only relevant tables based on the fixed timestamp */
      AND _TABLE_SUFFIX BETWEEN '20210105' AND '20210107'
  ) AS NDaysUsers
ON MDaysUsers.user_pseudo_id = NDaysUsers.user_pseudo_id
WHERE
  NDaysUsers.user_pseudo_id IS NULL;
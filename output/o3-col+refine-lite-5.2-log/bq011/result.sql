WITH engagement_7d AS (   -- users with positive engagement between 1‑Jan‑2021 and 7‑Jan‑2021
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'          -- 7‑day window
    AND ep.key = 'engagement_time_msec'
    AND ep.value.int_value > 0
),
engagement_2d AS (   -- users with positive engagement between 6‑Jan‑2021 and 7‑Jan‑2021
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
       UNNEST(event_params) AS ep
  WHERE _TABLE_SUFFIX BETWEEN '20210106' AND '20210107'          -- 2‑day window
    AND ep.key = 'engagement_time_msec'
    AND ep.value.int_value > 0
)
SELECT COUNT(*) AS num_distinct_users
FROM engagement_7d
WHERE user_pseudo_id NOT IN (SELECT user_pseudo_id FROM engagement_2d);
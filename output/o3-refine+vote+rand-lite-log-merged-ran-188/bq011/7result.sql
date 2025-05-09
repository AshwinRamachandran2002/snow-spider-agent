-- distinct pseudo‑users with positive engagement during Jan 1‑7 2021
-- who had no positive engagement during Jan 6‑7 2021
WITH engagement AS (
  -- all “user_engagement” events whose engagement_time_msec > 0
  SELECT
    user_pseudo_id,
    event_date
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202101*`
  WHERE event_name = 'user_engagement'
    AND event_date BETWEEN '20210101' AND '20210107'          -- 7‑day window
    AND EXISTS (                                              -- positive engagement
      SELECT 1
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'engagement_time_msec'
            AND SAFE_CAST(ep.value.int_value AS INT64) > 0
    )
),
set_7d AS (
  SELECT DISTINCT user_pseudo_id
  FROM engagement                                         -- Jan 1‑7
),
set_2d AS (
  SELECT DISTINCT user_pseudo_id
  FROM engagement
  WHERE event_date BETWEEN '20210106' AND '20210107'       -- Jan 6‑7
)
SELECT COUNT(*) AS distinct_pseudo_users
FROM set_7d
WHERE user_pseudo_id NOT IN (SELECT user_pseudo_id FROM set_2d);
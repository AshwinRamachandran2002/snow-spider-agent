-- number of distinct pseudo–users that had positive engagement time
-- in Jan 1‒7 2021 (inclusive) but none in Jan 6‒7 2021
WITH base AS (
  SELECT
    user_pseudo_id,
    event_date,
    SAFE_CAST((
      SELECT ep.value.int_value
      FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'engagement_time_msec'
    ) AS INT64) AS engagement_time_msec
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20210101' AND '20210107'          -- only tables for Jan 1‑7 2021
),
positive_engagement AS (
  SELECT DISTINCT user_pseudo_id, event_date
  FROM base
  WHERE engagement_time_msec IS NOT NULL
        AND engagement_time_msec > 0                              -- “positive engagement time”
),
engagement_7d AS (
  SELECT DISTINCT user_pseudo_id
  FROM positive_engagement
  WHERE event_date BETWEEN '20210101' AND '20210107'              -- whole 7‑day window
),
engagement_2d AS (
  SELECT DISTINCT user_pseudo_id
  FROM positive_engagement
  WHERE event_date BETWEEN '20210106' AND '20210107'              -- trailing 2‑day window
)
SELECT COUNT(*) AS distinct_users
FROM engagement_7d
WHERE user_pseudo_id NOT IN (SELECT user_pseudo_id FROM engagement_2d);
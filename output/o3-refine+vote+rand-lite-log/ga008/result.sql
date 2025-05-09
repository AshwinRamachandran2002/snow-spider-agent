-- Total page‑views per day in Nov‑2020 and average page‑views per user
-- (only for users who completed ≥1 purchase during Nov‑2020)

WITH purchasers AS (   -- 1. Users that purchased in Nov‑2020
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_name = 'purchase'
),

page_view_events AS ( -- 2. Their page‑view events in Nov‑2020
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_dt,
    user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_name = 'page_view'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM purchasers)
),

per_user_per_day AS ( -- 3. Count of page‑views per user per day
  SELECT
    event_dt,
    user_pseudo_id,
    COUNT(*) AS page_views_per_user
  FROM page_view_events
  GROUP BY event_dt, user_pseudo_id
)

-- 4. Final daily metrics
SELECT
  event_dt                        AS event_date,
  SUM(page_views_per_user)        AS total_page_views,
  AVG(page_views_per_user)        AS avg_page_views_per_user
FROM per_user_per_day
GROUP BY event_dt
ORDER BY event_dt;
/*  Daily page‑view totals & per‑user averages in Nov‑2020,
    limited to users who recorded at least one purchase in Nov‑2020  */

WITH purchase_users AS (               -- 1. users who purchased in Nov‑2020
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_name = 'purchase'        -- GA4 purchase event
),

pageviews AS (                         -- 2. page‑view events from those users
  SELECT
    event_date,                        -- YYYYMMDD string
    user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE event_name = 'page_view'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM purchase_users)
),

pv_per_user AS (                       -- 3. pv count per user per day
  SELECT
    event_date,
    user_pseudo_id,
    COUNT(*) AS pv_cnt
  FROM pageviews
  GROUP BY event_date, user_pseudo_id
)

SELECT                                  -- 4. daily aggregates
  event_date,
  SUM(pv_cnt)                                   AS total_page_views,
  AVG(pv_cnt)                                   AS avg_page_views_per_user
FROM pv_per_user
GROUP BY event_date
ORDER BY event_date;
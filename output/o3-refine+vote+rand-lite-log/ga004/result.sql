-- Average difference in page‑views between purchasers and non‑purchasers
WITH dec_events AS (
  SELECT
    user_pseudo_id,
    event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  -- * has suffixes '01' … '31'; keep only those to be explicit
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'
),
per_user AS (
  SELECT
    user_pseudo_id,
    COUNTIF(event_name = 'page_view')            AS pageviews,
    MAX(IF(event_name = 'purchase', 1, 0)) = 1   AS is_purchaser
  FROM dec_events
  GROUP BY user_pseudo_id
)
SELECT
  AVG(IF(is_purchaser, pageviews, NULL)) 
  - 
  AVG(IF(NOT is_purchaser, pageviews, NULL)) AS avg_pageviews_difference
FROM per_user;
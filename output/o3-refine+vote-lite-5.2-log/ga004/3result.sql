WITH dec_events AS (
  -- grab only December‑2020 data
  SELECT
    user_pseudo_id,
    event_name
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE
    user_pseudo_id IS NOT NULL                 -- safety
    AND event_name IN ('page_view','purchase') -- we only need these two
),
user_level AS (
  -- page‑views and “purchaser” flag per user
  SELECT
    user_pseudo_id,
    SUM(CASE WHEN event_name = 'page_view' THEN 1 ELSE 0 END) AS pageviews,
    MAX(CASE WHEN event_name = 'purchase'   THEN 1 ELSE 0 END) AS is_purchaser
  FROM dec_events
  GROUP BY user_pseudo_id
),
avg_by_group AS (
  -- average page‑views for purchasers vs. non‑purchasers
  SELECT
    is_purchaser,
    AVG(pageviews) AS avg_pageviews
  FROM user_level
  GROUP BY is_purchaser
),
pivot AS (
  SELECT
    MAX(CASE WHEN is_purchaser = 1 THEN avg_pageviews END) AS avg_pageviews_purchasers,
    MAX(CASE WHEN is_purchaser = 0 THEN avg_pageviews END) AS avg_pageviews_non_purchasers
  FROM avg_by_group
)
SELECT
  avg_pageviews_purchasers,
  avg_pageviews_non_purchasers,
  avg_pageviews_purchasers - avg_pageviews_non_purchasers AS avg_pageview_difference
FROM pivot;
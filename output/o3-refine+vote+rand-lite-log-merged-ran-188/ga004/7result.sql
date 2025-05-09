WITH december_2020 AS (
  -- pull only December‑2020 events
  SELECT
    user_pseudo_id,
    event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'      -- keep only 20201201‑31 shards
),

per_user AS (
  -- page‑view count and purchaser flag per user
  SELECT
    user_pseudo_id,
    SUM(CASE WHEN event_name = 'page_view' THEN 1 ELSE 0 END)           AS pageviews,
    MAX(CASE WHEN event_name = 'purchase'   THEN 1 ELSE 0 END) AS is_purchaser  -- 1 if any purchase
  FROM december_2020
  GROUP BY user_pseudo_id
),

group_avgs AS (
  SELECT
    AVG(CASE WHEN is_purchaser = 1 THEN pageviews END) AS avg_pageviews_purchasers,
    AVG(CASE WHEN is_purchaser = 0 THEN pageviews END) AS avg_pageviews_nonpurchasers
  FROM per_user
)

SELECT
  avg_pageviews_purchasers - avg_pageviews_nonpurchasers AS avg_pageview_difference
FROM group_avgs;
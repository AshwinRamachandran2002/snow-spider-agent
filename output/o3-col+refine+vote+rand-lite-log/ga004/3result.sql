-- Average difference in December-2020 pageviews between purchasers and non-purchasers
WITH pageviews AS (               -- count December pageviews per user
  SELECT
    user_pseudo_id,
    COUNT(*) AS pageviews
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'page_view'
  GROUP BY user_pseudo_id
),
purchasers AS (                   -- flag users who generated a purchase
  SELECT DISTINCT
    user_pseudo_id,
    1 AS is_purchaser
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'purchase'
),
avg_views AS (                    -- average pageviews for each group
  SELECT
    IFNULL(pr.is_purchaser, 0)      AS is_purchaser,
    AVG(pv.pageviews)               AS avg_pageviews
  FROM pageviews pv
  LEFT JOIN purchasers pr
    ON pv.user_pseudo_id = pr.user_pseudo_id
  GROUP BY is_purchaser
)
SELECT
  MAX(IF(is_purchaser = 1, avg_pageviews, NULL))  -- purchasers’ average
  -
  MAX(IF(is_purchaser = 0, avg_pageviews, NULL))  -- non-purchasers’ average
    AS avg_pageview_difference
FROM avg_views;
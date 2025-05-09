-- Average pageview difference between purchasers and non-purchasers in December-2020
WITH per_user AS (
  SELECT
    `user_pseudo_id`,
    SUM(CASE WHEN `event_name` = 'page_view' THEN 1 ELSE 0 END) AS pageviews,
    MAX(CASE WHEN `event_name` = 'purchase' THEN 1 ELSE 0 END) AS purchased   -- 1 = purchaser, 0 = non-purchaser
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
  GROUP BY `user_pseudo_id`
),
summary AS (
  SELECT
    AVG(IF(purchased = 1, pageviews, NULL)) AS avg_pageviews_purchasers,
    AVG(IF(purchased = 0, pageviews, NULL)) AS avg_pageviews_non_purchasers
  FROM per_user
)
SELECT
  avg_pageviews_purchasers,
  avg_pageviews_non_purchasers,
  avg_pageviews_purchasers - avg_pageviews_non_purchasers AS avg_pageview_difference
FROM summary;
WITH pageviews AS (
  -- page-views each user generated in December 2020
  SELECT
    user_pseudo_id,
    COUNT(*) AS pageviews
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'page_view'
  GROUP BY user_pseudo_id
),
purchasers AS (
  -- any user who fired at least one purchase event in December 2020
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'purchase'
),
combined AS (
  -- join the two lists and flag purchasers
  SELECT
    pv.user_pseudo_id,
    pv.pageviews,
    IF(pr.user_pseudo_id IS NOT NULL, 1, 0) AS is_purchaser
  FROM pageviews pv
  LEFT JOIN purchasers pr
  USING (user_pseudo_id)
)
-- difference between the two cohort averages
SELECT
  AVG(IF(is_purchaser = 1, pageviews, NULL)) -
  AVG(IF(is_purchaser = 0, pageviews, NULL)) AS avg_pageview_difference
FROM combined;
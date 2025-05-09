-- Average page-views for purchasers vs. non-purchasers in December-2020
WITH pageviews AS (
  SELECT
    user_pseudo_id,
    COUNT(*) AS pageviews
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'page_view'
  GROUP BY user_pseudo_id
),
purchasers AS (
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'purchase'
),
labeled AS (
  SELECT
    pv.user_pseudo_id,
    pv.pageviews,
    IF(pur.user_pseudo_id IS NULL, 0, 1) AS is_purchaser
  FROM pageviews pv
  LEFT JOIN purchasers pur
  USING (user_pseudo_id)
)
SELECT
  ROUND(AVG(CASE WHEN is_purchaser = 1 THEN pageviews END), 4) AS avg_pageviews_purchasers,
  ROUND(AVG(CASE WHEN is_purchaser = 0 THEN pageviews END), 4) AS avg_pageviews_non_purchasers,
  ROUND(
    AVG(CASE WHEN is_purchaser = 1 THEN pageviews END)
    - AVG(CASE WHEN is_purchaser = 0 THEN pageviews END)
  , 4) AS avg_difference
FROM labeled;
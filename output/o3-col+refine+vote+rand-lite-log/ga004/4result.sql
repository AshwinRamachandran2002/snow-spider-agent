-- Average page-views for purchasers vs. non-purchasers in December 2020
WITH per_user AS (
  SELECT
    user_pseudo_id,
    COUNTIF(event_name = 'page_view')                                        AS pageviews,
    MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END)                AS is_purchaser
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  GROUP BY user_pseudo_id
),
summary AS (
  SELECT
    AVG(CASE WHEN is_purchaser = 1 THEN pageviews END) AS avg_purchasers,
    AVG(CASE WHEN is_purchaser = 0 THEN pageviews END) AS avg_non_purchasers
  FROM per_user
)
SELECT
  avg_purchasers,
  avg_non_purchasers,
  avg_purchasers - avg_non_purchasers AS avg_pageview_difference
FROM summary;
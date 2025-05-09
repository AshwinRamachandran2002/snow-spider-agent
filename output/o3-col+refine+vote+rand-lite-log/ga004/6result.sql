WITH user_pageviews AS (
  SELECT
    user_pseudo_id,
    SUM(CASE WHEN event_name = 'page_view' THEN 1 ELSE 0 END) AS pageviews,
    MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS purchaser_flag
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  GROUP BY user_pseudo_id
),
avg_by_group AS (
  SELECT
    purchaser_flag,
    AVG(pageviews) AS avg_pageviews
  FROM user_pageviews
  GROUP BY purchaser_flag
)
SELECT
  ROUND(
    ABS(
      MAX(IF(purchaser_flag = 1, avg_pageviews, NULL)) -
      MAX(IF(purchaser_flag = 0, avg_pageviews, NULL))
    ), 4
  ) AS avg_pageview_difference
FROM avg_by_group;
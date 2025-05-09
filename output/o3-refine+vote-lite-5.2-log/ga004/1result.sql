-- Average page‑views for purchasers vs. non‑purchasers in December 2020
WITH dec_events AS (
  SELECT
    user_pseudo_id,
    event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
),
user_level AS (
  SELECT
    user_pseudo_id,
    COUNTIF(event_name = 'page_view')                                         AS pageviews,
    IF(COUNTIF(event_name = 'purchase') > 0, 1, 0)                           AS purchaser
  FROM dec_events
  GROUP BY user_pseudo_id
)
SELECT
  ROUND(AVG(IF(purchaser = 1, pageviews, NULL)), 4)  AS avg_pageviews_purchasers,
  ROUND(AVG(IF(purchaser = 0, pageviews, NULL)), 4)  AS avg_pageviews_nonpurchasers,
  ROUND(
        AVG(IF(purchaser = 1, pageviews, NULL))
      - AVG(IF(purchaser = 0, pageviews, NULL))
  , 4)                                                    AS avg_difference
FROM user_level;
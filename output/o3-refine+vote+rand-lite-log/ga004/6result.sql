WITH dec_events AS (
  SELECT
    user_pseudo_id,
    event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'            -- only 1‑31 Dec 2020
),
per_user AS (
  SELECT
    user_pseudo_id,
    COUNTIF(event_name = 'page_view')                     AS pageviews,
    COUNTIF(event_name = 'purchase') > 0                 AS made_purchase   -- TRUE = purchaser
  FROM dec_events
  GROUP BY user_pseudo_id
)
SELECT
  ROUND(AVG(CASE WHEN made_purchase THEN pageviews END), 4)  AS avg_pageviews_purchasers,
  ROUND(AVG(CASE WHEN NOT made_purchase THEN pageviews END), 4) AS avg_pageviews_non_purchasers,
  ROUND(
        AVG(CASE WHEN made_purchase THEN pageviews END)
      - AVG(CASE WHEN NOT made_purchase THEN pageviews END)
  , 4)                                                      AS avg_pageview_difference
FROM per_user;
WITH dec_events AS (
  -- All events from December 2020
  SELECT
    user_pseudo_id,
    event_name
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
),
purchasers AS (
  -- Anyone who generated at least one “purchase” event
  SELECT DISTINCT user_pseudo_id
  FROM dec_events
  WHERE event_name = 'purchase'
),
pageviews_per_user AS (
  -- Count December page-views for every user
  SELECT
    user_pseudo_id,
    COUNTIF(event_name = 'page_view') AS pageviews
  FROM dec_events
  GROUP BY user_pseudo_id
),
averages AS (
  -- Average page-views for purchasers vs non-purchasers
  SELECT
    CASE
      WHEN p.user_pseudo_id IS NOT NULL THEN 'Purchaser'
      ELSE 'Non_Purchaser'
    END AS user_type,
    AVG(pageviews) AS avg_pageviews
  FROM pageviews_per_user v
  LEFT JOIN purchasers p
    ON v.user_pseudo_id = p.user_pseudo_id
  GROUP BY user_type
)
-- Difference in averages (purchasers – non-purchasers)
SELECT
  ROUND(
        MAX(CASE WHEN user_type = 'Purchaser'     THEN avg_pageviews END)
      - MAX(CASE WHEN user_type = 'Non_Purchaser' THEN avg_pageviews END)
      , 4) AS avg_pageview_difference
FROM averages;
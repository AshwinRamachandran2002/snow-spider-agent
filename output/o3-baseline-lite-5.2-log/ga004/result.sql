/* Average difference in page‑views (December‑2020) between purchasers
   (users with at least one “purchase” event) and non‑purchasers          */

WITH dec_events AS (
  -- all GA4 events for December‑2020
  SELECT
    user_pseudo_id,
    event_name
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
),

purchasers AS (
  -- anybody who triggered a “purchase” event
  SELECT DISTINCT
    user_pseudo_id
  FROM dec_events
  WHERE event_name = 'purchase'
),

pageviews_per_user AS (
  -- page‑view count per user in December‑2020
  SELECT
    user_pseudo_id,
    COUNTIF(event_name = 'page_view') AS pageviews
  FROM dec_events
  GROUP BY user_pseudo_id
),

labeled_users AS (
  -- flag users as purchaser / non‑purchaser
  SELECT
    pvu.user_pseudo_id,
    pvu.pageviews,
    IF(p.user_pseudo_id IS NULL, 'non_purchaser', 'purchaser') AS purchaser_flag
  FROM pageviews_per_user AS pvu
  LEFT JOIN purchasers AS p
  USING (user_pseudo_id)
)

SELECT
  AVG(CASE WHEN purchaser_flag = 'purchaser'      THEN pageviews END) AS avg_pageviews_purchaser,
  AVG(CASE WHEN purchaser_flag = 'non_purchaser'  THEN pageviews END) AS avg_pageviews_non_purchaser,
  AVG(CASE WHEN purchaser_flag = 'purchaser'      THEN pageviews END) -
  AVG(CASE WHEN purchaser_flag = 'non_purchaser'  THEN pageviews END) AS diff_pageviews
FROM labeled_users;
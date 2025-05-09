WITH per_user AS (
  SELECT
    user_pseudo_id,
    COUNTIF(event_name = 'page_view')  AS pageviews,
    COUNTIF(event_name = 'purchase')   AS purchases
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  GROUP BY user_pseudo_id
),
averages AS (
  SELECT
    AVG(CASE WHEN purchases > 0 THEN pageviews END) AS avg_pageviews_purchasers,
    AVG(CASE WHEN purchases = 0 THEN pageviews END) AS avg_pageviews_non_purchasers
  FROM per_user
)
SELECT
  ROUND(avg_pageviews_purchasers, 4)       AS avg_pageviews_purchasers,
  ROUND(avg_pageviews_non_purchasers, 4)   AS avg_pageviews_non_purchasers,
  ROUND(
    avg_pageviews_purchasers - avg_pageviews_non_purchasers,
    4
  )                                        AS avg_pageviews_difference
FROM averages;
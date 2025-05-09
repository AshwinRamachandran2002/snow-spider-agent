WITH purchasers AS (
  SELECT DISTINCT `user_pseudo_id`
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE `event_name` = 'purchase'
),
avg_pageviews_purchasers AS (
  SELECT AVG(pageviews) AS avg_pageviews_purchasers
  FROM (
    SELECT `user_pseudo_id`, COUNT(*) AS pageviews
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
    WHERE `event_name` = 'page_view'
      AND `user_pseudo_id` IN (SELECT `user_pseudo_id` FROM purchasers)
    GROUP BY `user_pseudo_id`
  )
),
avg_pageviews_non_purchasers AS (
  SELECT AVG(pageviews) AS avg_pageviews_non_purchasers
  FROM (
    SELECT `user_pseudo_id`, COUNT(*) AS pageviews
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
    WHERE `event_name` = 'page_view'
      AND `user_pseudo_id` NOT IN (SELECT `user_pseudo_id` FROM purchasers)
    GROUP BY `user_pseudo_id`
  )
)
SELECT
  ROUND(
    avg_pageviews_purchasers.avg_pageviews_purchasers - avg_pageviews_non_purchasers.avg_pageviews_non_purchasers,
    4
  ) AS Average_Difference_in_Pageviews
FROM avg_pageviews_purchasers, avg_pageviews_non_purchasers;
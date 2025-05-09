-- Daily page-views and average per user for the November-2020 purchaser cohort
WITH purchasers AS (
  -- Users who made at least one purchase during November-2020
  SELECT DISTINCT `user_pseudo_id`
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND `event_name` = 'purchase'
),
daily_pageviews AS (
  -- Page-view activity in November-2020 restricted to the purchaser cohort
  SELECT
    _TABLE_SUFFIX                         AS `event_date`,
    COUNT(*)                              AS `total_page_views`,
    COUNT(DISTINCT `user_pseudo_id`)      AS `active_purchasers`
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND `event_name` = 'page_view'
    AND `user_pseudo_id` IN (SELECT `user_pseudo_id` FROM purchasers)
  GROUP BY `event_date`
)
SELECT
  `event_date`,
  `total_page_views`,
  SAFE_DIVIDE(`total_page_views`, `active_purchasers`) AS `avg_page_views_per_user`
FROM daily_pageviews
ORDER BY `event_date`;
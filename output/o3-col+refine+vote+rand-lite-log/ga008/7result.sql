-- Daily total and average page-views in Nov-2020,
-- restricted to users who purchased at least once in Nov-2020
WITH purchasers AS (
  SELECT DISTINCT `user_pseudo_id`
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE `event_name` = 'purchase'
),
daily_user_pv AS (
  SELECT
    `event_date`,
    `user_pseudo_id`,
    COUNT(*) AS pv
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202011*`
  WHERE `event_name` = 'page_view'
    AND `user_pseudo_id` IN (SELECT `user_pseudo_id` FROM purchasers)
  GROUP BY `event_date`, `user_pseudo_id`
)
SELECT
  PARSE_DATE('%Y%m%d', `event_date`) AS calendar_date,
  SUM(pv)                            AS total_page_views,
  AVG(pv)                            AS avg_page_views_per_user
FROM daily_user_pv
GROUP BY calendar_date
ORDER BY calendar_date;
SELECT
  event_date AS date,
  COUNT(*) AS total_page_views,
  ROUND(COUNT(*) / COUNT(DISTINCT user_pseudo_id), 4) AS avg_page_views_per_user
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
  AND event_name = 'page_view'
  AND user_pseudo_id IN (
        SELECT DISTINCT user_pseudo_id
        FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
        WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
          AND event_name = 'purchase'
      )
GROUP BY event_date
ORDER BY event_date;
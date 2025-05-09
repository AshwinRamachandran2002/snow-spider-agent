WITH purchasers AS (
  -- Users who made at least one purchase in Nov-2020
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND event_name = 'purchase'
),
daily_pvs AS (
  -- Page-view counts per purchaser per day
  SELECT
    _TABLE_SUFFIX AS event_date,
    user_pseudo_id,
    COUNTIF(event_name = 'page_view') AS pageviews_per_user
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM purchasers)
  GROUP BY event_date, user_pseudo_id
)
-- Final daily totals & averages
SELECT
  event_date,
  SUM(pageviews_per_user) AS total_pageviews,
  AVG(pageviews_per_user) AS avg_pageviews_per_user
FROM daily_pvs
GROUP BY event_date
ORDER BY event_date;
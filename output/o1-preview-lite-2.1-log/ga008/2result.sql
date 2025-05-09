WITH buyers AS (
  SELECT DISTINCT user_pseudo_id, event_date
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'purchase'
    AND event_date BETWEEN '20201101' AND '20201130'
    AND _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
),
page_views AS (
  SELECT
    event_date,
    user_pseudo_id,
    COUNT(*) AS page_views
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'page_view'
    AND event_date BETWEEN '20201101' AND '20201130'
    AND _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
  GROUP BY event_date, user_pseudo_id
),
joined_data AS (
  SELECT
    buyers.event_date,
    buyers.user_pseudo_id,
    IFNULL(page_views.page_views, 0) AS page_views
  FROM buyers
  LEFT JOIN page_views
    ON buyers.user_pseudo_id = page_views.user_pseudo_id
    AND buyers.event_date = page_views.event_date
)
SELECT
  event_date,
  AVG(page_views) AS Average_Page_Views_per_Buyer,
  SUM(page_views) AS Total_Page_Views_Among_Buyers
FROM joined_data
GROUP BY event_date
ORDER BY event_date;
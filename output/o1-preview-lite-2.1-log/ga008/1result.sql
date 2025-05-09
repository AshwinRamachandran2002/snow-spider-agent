WITH all_events AS (
  SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201102`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201103`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201104`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201105`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201106`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201107`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201108`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201109`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201110`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201111`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201112`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201113`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201114`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201115`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201116`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201117`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201118`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201119`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201120`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201121`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201122`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201123`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201124`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201125`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201126`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201127`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201128`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201129`
  UNION ALL SELECT event_date, event_name, user_pseudo_id FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`
),
buyers AS (
  SELECT DISTINCT event_date, user_pseudo_id
  FROM all_events
  WHERE event_name = 'purchase'
),
buyers_pageviews AS (
  SELECT event_date, user_pseudo_id
  FROM all_events
  WHERE event_name = 'page_view'
),
buyers_pageviews_joined AS (
  SELECT p.event_date, p.user_pseudo_id
  FROM buyers_pageviews p
  JOIN buyers b
    ON p.event_date = b.event_date
    AND p.user_pseudo_id = b.user_pseudo_id
),
pageviews_per_buyer AS (
  SELECT event_date, user_pseudo_id, COUNT(*) AS page_views
  FROM buyers_pageviews_joined
  GROUP BY event_date, user_pseudo_id
)
SELECT
  event_date AS Date,
  ROUND(AVG(page_views), 4) AS Average_Page_Views_per_Buyer,
  SUM(page_views) AS Total_Page_Views_Among_Buyers
FROM pageviews_per_buyer
GROUP BY event_date
ORDER BY event_date;
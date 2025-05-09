WITH unioned_tables AS (
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201102`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201103`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201104`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201105`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201106`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201107`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201108`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201109`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201110`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201111`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201112`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201113`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201114`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201115`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201116`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201117`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201118`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201119`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201120`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201121`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201122`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201123`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201124`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201125`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201126`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201127`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201128`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201129`
  UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`
),
buyers AS (
  SELECT event_date, user_pseudo_id
  FROM unioned_tables
  WHERE event_name = 'purchase'
  GROUP BY event_date, user_pseudo_id
),
buyer_page_views AS (
  SELECT event_date, user_pseudo_id, COUNT(*) AS page_views
  FROM unioned_tables
  WHERE event_name = 'page_view'
  GROUP BY event_date, user_pseudo_id
),
buyer_page_views_on_purchase_date AS (
  SELECT pv.event_date, pv.user_pseudo_id, pv.page_views
  FROM buyer_page_views pv
  INNER JOIN buyers b
    ON pv.event_date = b.event_date AND pv.user_pseudo_id = b.user_pseudo_id
),
daily_metrics AS (
  SELECT event_date AS Date,
         ROUND(AVG(page_views), 4) AS Average_Page_Views_per_Buyer,
         SUM(page_views) AS Total_Page_Views_Among_Buyers
  FROM buyer_page_views_on_purchase_date
  GROUP BY event_date
  ORDER BY event_date
)
SELECT Date, Average_Page_Views_per_Buyer, Total_Page_Views_Among_Buyers
FROM daily_metrics;
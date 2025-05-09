WITH
  all_events AS (
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
  purchasers AS (
    SELECT DISTINCT user_pseudo_id
    FROM all_events
    WHERE event_name = 'purchase'
  ),
  page_views AS (
    SELECT event_date, user_pseudo_id
    FROM all_events
    WHERE event_name = 'page_view'
  )
SELECT
  FORMAT_DATE('%Y-%m-%d', PARSE_DATE('%Y%m%d', pv.event_date)) AS Date,
  SUM(pv.user_page_views) AS Total_Page_Views,
  ROUND(AVG(pv.user_page_views), 4) AS Average_Page_Views_Per_User
FROM (
  SELECT
    pv.event_date,
    pv.user_pseudo_id,
    COUNT(*) AS user_page_views
  FROM page_views pv
  INNER JOIN purchasers p
    ON pv.user_pseudo_id = p.user_pseudo_id
  GROUP BY pv.event_date, pv.user_pseudo_id
) AS pv
GROUP BY pv.event_date
ORDER BY pv.event_date;
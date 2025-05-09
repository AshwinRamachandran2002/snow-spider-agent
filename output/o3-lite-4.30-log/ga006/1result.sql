WITH all_events AS (
  SELECT * FROM (
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201102`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201103`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201104`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201105`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201106`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201107`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201108`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201109`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201110`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201111`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201112`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201113`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201114`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201115`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201116`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201117`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201118`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201119`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201120`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201121`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201122`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201123`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201124`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201125`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201126`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201127`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201128`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201129`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`
  )
),
purchase_events AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) AS ep
     WHERE ep.key = 'ga_session_id'
     LIMIT 1) AS ga_session_id,
    ecommerce.purchase_revenue_in_usd AS purchase_revenue_usd
  FROM all_events
  WHERE event_name = 'purchase'
    AND ecommerce.purchase_revenue_in_usd IS NOT NULL
),
session_revenue AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    SUM(purchase_revenue_usd) AS session_revenue_usd
  FROM purchase_events
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
)
SELECT
  user_pseudo_id,
  ROUND(AVG(session_revenue_usd), 4) AS avg_purchase_revenue_usd_per_session
FROM session_revenue
GROUP BY user_pseudo_id
HAVING COUNT(*) > 1
ORDER BY avg_purchase_revenue_usd_per_session DESC;
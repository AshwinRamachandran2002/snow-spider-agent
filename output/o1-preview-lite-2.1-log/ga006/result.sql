SELECT
  user_pseudo_id AS user_id,
  ROUND(AVG(purchase_value_usd), 4) AS average_purchase_value_usd
FROM (
  SELECT
    user_pseudo_id,
    transaction_id,
    SUM(purchase_revenue_in_usd) AS purchase_value_usd
  FROM (
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201101`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201102`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201103`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201104`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201105`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201106`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201107`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201108`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201109`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201110`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201111`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201112`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201113`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201114`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201115`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201116`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201117`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201118`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201119`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201120`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201121`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201122`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201123`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201124`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201125`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201126`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201127`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201128`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201129`
    UNION ALL
    SELECT
      user_pseudo_id,
      event_name,
      ecommerce.transaction_id AS transaction_id,
      ecommerce.purchase_revenue_in_usd
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201130`
  ) AS unioned_events
  WHERE
    event_name = 'purchase'
    AND transaction_id IS NOT NULL
    AND purchase_revenue_in_usd IS NOT NULL
  GROUP BY
    user_pseudo_id,
    transaction_id
)
GROUP BY
  user_id
HAVING
  COUNT(DISTINCT transaction_id) > 1
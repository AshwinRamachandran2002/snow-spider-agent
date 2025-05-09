SELECT COUNT(DISTINCT active_users.user_pseudo_id) AS Number_of_pseudo_users
FROM (
  SELECT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201231`
  UNION ALL
  SELECT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210101`
  UNION ALL
  SELECT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  UNION ALL
  SELECT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210103`
  UNION ALL
  SELECT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210104`
  UNION ALL
  SELECT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210105`
) AS active_users
WHERE active_users.user_pseudo_id NOT IN (
  SELECT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210106`
  UNION ALL
  SELECT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210107`
);
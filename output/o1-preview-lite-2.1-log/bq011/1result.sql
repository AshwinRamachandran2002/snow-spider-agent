SELECT COUNT(DISTINCT user_pseudo_id) AS Number_of_pseudo_users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201231' AND '20210105'
  AND user_pseudo_id NOT IN (
    SELECT DISTINCT user_pseudo_id
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE _TABLE_SUFFIX IN ('20210106', '20210107')
  );
WITH all_events AS (
  SELECT user_pseudo_id, event_name FROM (
    SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201201`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201202`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201203`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201204`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201205`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201206`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201207`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201208`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201209`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201210`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201211`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201212`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201213`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201214`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201215`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201216`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201217`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201218`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201219`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201220`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201221`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201222`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201223`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201224`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201225`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201226`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201227`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201228`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201229`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201230`
    UNION ALL SELECT user_pseudo_id, event_name FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201231`
  )
),
per_user AS (
  SELECT
    user_pseudo_id,
    SUM(CASE WHEN event_name = 'page_view' THEN 1 ELSE 0 END) AS pageviews,
    MAX(CASE WHEN event_name = 'purchase' THEN 1 ELSE 0 END) AS is_purchaser
  FROM all_events
  GROUP BY user_pseudo_id
),
agg AS (
  SELECT
    AVG(IF(is_purchaser = 1, pageviews, NULL)) AS avg_purchaser,
    AVG(IF(is_purchaser = 0, pageviews, NULL)) AS avg_non_purchaser
  FROM per_user
)
SELECT
  ROUND(avg_purchaser - avg_non_purchaser, 4) AS average_pageviews_difference
FROM agg;
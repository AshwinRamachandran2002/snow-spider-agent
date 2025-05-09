WITH jan_events AS (
  SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210101`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210102`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210103`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210104`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210105`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210106`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210107`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210108`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210109`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210110`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210111`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210112`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210113`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210114`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210115`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210116`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210117`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210118`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210119`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210120`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210121`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210122`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210123`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210124`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210125`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210126`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210127`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210128`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210129`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210130`
  UNION ALL SELECT event_name, user_pseudo_id, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
),
top_page AS (
  SELECT ep.value.string_value AS page_location
  FROM jan_events, UNNEST(event_params) AS ep
  WHERE event_name = 'page_view'
    AND ep.key = 'page_location'
  GROUP BY page_location
  ORDER BY COUNT(*) DESC
  LIMIT 1
)
SELECT COUNT(DISTINCT je.user_pseudo_id) AS distinct_user_count
FROM jan_events AS je
JOIN UNNEST(je.event_params) AS ep
  ON ep.key = 'page_location'
JOIN top_page tp
  ON ep.value.string_value = tp.page_location
WHERE je.event_name = 'page_view';
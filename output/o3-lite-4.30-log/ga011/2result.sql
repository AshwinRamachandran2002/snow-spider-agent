WITH december_events AS (
  SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201201`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201202`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201203`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201204`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201205`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201206`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201207`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201208`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201209`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201210`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201211`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201212`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201213`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201214`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201215`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201216`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201217`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201218`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201219`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201220`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201221`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201222`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201223`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201224`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201225`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201226`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201227`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201228`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201229`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201230`
  UNION ALL SELECT event_name, event_params FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201231`
),
pageviews AS (
  SELECT
    REGEXP_REPLACE(
      REGEXP_EXTRACT(ep.value.string_value, r'https?://[^/]+(/.*)'),
      r'/+',
      '/'
    ) AS page_path
  FROM december_events
  CROSS JOIN UNNEST(event_params) AS ep
  WHERE event_name = 'page_view'
    AND ep.key                      = 'page_location'
    AND LOWER(ep.value.string_value) LIKE '%shop.googlemerchandisestore.com%'
),
totals AS (
  SELECT page_path, COUNT(*) AS total_page_views
  FROM pageviews
  GROUP BY page_path
)
SELECT page_path, total_page_views
FROM totals
ORDER BY total_page_views DESC, page_path
LIMIT 1 OFFSET 1;